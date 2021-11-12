from docx import Document as Doc
import sys
import json
import argparse
import re
from lxml import etree
import xml.dom.minidom
from pathlib import Path
from uuid import uuid4

from docx.document import Document
from docx.oxml.table import CT_Tbl
from docx.oxml.section import CT_SectPr
from docx.oxml.text.paragraph import CT_P
from docx.oxml.text.run import CT_R
from docx.oxml.text.parfmt import CT_PPr
from docx.table import _Cell, Table
from docx.text.paragraph import Paragraph
from docx.opc.constants import RELATIONSHIP_TYPE as RT

parts_reg = re.compile('Security Control: ([0-9]+); Revision: ([0-9]+); '
        'Updated: ([^;]+); Applicability: (.*)$')

class Control:
    def __init__(self, tag):
        text = tag.text.replace('\n', ' ')
        parts = parts_reg.match(text)

        self.number = parts.group(1)
        self.revision = parts.group(2)
        self.update = parts.group(3)
        self.applicability = parts.group(4).replace(' ', '').split(',')
        self.o = 'O' in self.applicability
        self.p = 'P' in self.applicability
        self.s = 'S' in self.applicability
        self.ts = 'TS' in self.applicability

    def __str__(self):
        return('Security Control: {}; Revision: {}; Updated: {}; Applicability: {}'.format(
            self.number,
            self.revision,
            self.update,
            ', '.join(self.applicability)))

    def __repr__(self):
        return self.__str__()

    def _get_description(self, tag):
        description = []
        _next = tag
        while( True ):
            _next = _next.findNext(['p', 'ul', 'ol', 'h3'])
            if (_next.text.startswith('Security Control:') or
                    _next.name == 'h3'):
                break
            else: description.append(_next)
        return description

''' oxml constants '''
ID = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id'
HYPERLINK = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}hyperlink'


def iter_block_items(parent):
    """
    Yield each paragraph and table child within *parent*, in document order.
    Each returned value is an instance of either Table or Paragraph. *parent*
    would most commonly be a reference to a main Document object, but
    also works for a _Cell object, which itself can contain paragraphs and tables.
    """
    if isinstance(parent, Document):
        parent_elm = parent.element.body
    elif isinstance(parent, _Cell):
        parent_elm = parent._tc
    else:
        raise ValueError(f"Document contains unhandled element: {type(parent)}")

    for child in parent_elm.iterchildren():
        if isinstance(child, CT_P):
            yield Paragraph(child, parent)
        elif isinstance(child, CT_Tbl):
            yield Table(child, parent)
        elif isinstance(child, CT_SectPr):
            pass
        else:
            # We don't handle anything else...
            raise Exception(f"Document contains unhandled element: {type(child)}")

def add_table(para, node):
    """
    Given a paragraph and an etree node, builds the table as child elements to the node
    """
    table = etree.SubElement(node, 'table')
    for row in para.rows:
        tr = etree.SubElement(table, 'tr')
        for cell in row.cells:
            data = etree.SubElement(tr, 'td')
            data.text = cell.text

def add_attribs(control):
    detail = Control(control)

    control.attrib['number'] = detail.number
    control.attrib['revision'] = detail.revision
    control.attrib['update'] = detail.update
    control.attrib['official'] = str(detail.o)
    control.attrib['protected'] = str(detail.p)
    control.attrib['secret'] = str(detail.s)
    control.attrib['top_secret'] = str(detail.ts)

def baseline_control(control, baseline):
    '''
    Add a control to the relevant baselines
    '''
    for classification in ['official', 'protected', 'secret', 'top_secret']:
        if control.attrib[classification]:
            baseline[classification]['controls'] += [str(control.attrib['number'])]

### MAIN ###
parser = argparse.ArgumentParser(description='Parse an ISM docx file into XML')
parser.add_argument('-i', '--ism', dest='infile', help='path to the ISM docx file', required=True)
parser.add_argument('-o', '--xmlout', dest='xmloutfile', default='output.xml', help='path to the XML output file')
parser.add_argument('-c', '--catalog', dest='catalogfile', default='output.json', help='path to the JSON catalog file')
parser.add_argument('-b', '--oscal', dest='oscal', action='store_true', help='write out links as back-matter')
parser.add_argument('-p', '--pretty', dest='pretty', action='store_true', help='pretty print the output')
args = parser.parse_args()

if not Path(args.infile).is_file():
    print('{} is not a file'.format(args.infile))
    sys.exit(1)

try:
    '''
    import the document and rels file
    create uuids for links
    '''
    doc = Doc(args.infile)
    rels = doc.part.rels
    uuids = {}
    id_list = {}
    for rel in rels:
        if rels[rel]._target not in id_list:
            id_list[rels[rel]._target] = str(uuid4())
        if rels[rel]._is_external:
            uuids[rel] = id_list[rels[rel]._target]

except Exception as exc:
    print('{} is not a valid docx file: {}'.format(args.infile, exc))
    sys.exit(1)

root = etree.Element('root')
root.attrib['xmlns'] = "http://csrc.nist.gov/ns/oscal/1.0"
ism = etree.SubElement(root, 'ism')
node = None

meta = etree.SubElement(ism, 'metadata')
meta.attrib['uuid'] = str(uuid4())
modified = etree.SubElement(meta, 'modified')
modified.text = doc.core_properties.modified.isoformat() + ".000+10:00"
version = etree.SubElement(meta, 'version')
version.text = doc.core_properties.modified.strftime('%Y-%m-%d')
acsc_version = etree.SubElement(meta, 'acsc_version')
acsc_version.text = doc.core_properties.modified.strftime('%B %Y')

baselines = {'official':{'controls':[]},
             'protected':{'controls':[]},
             'secret':{'controls':[]},
             'top_secret':{'controls':[]}}

for para in iter_block_items(doc):
    if para.style.name == 'Heading 1':
        title = etree.SubElement(ism, 'title')
        text = etree.SubElement(title, 'titletext')
        text.text = para.text
        node = title
    elif para.style.name == 'Heading 2':
        section = etree.SubElement(title, 'section')
        text = etree.SubElement(section, 'sectiontext')
        text.text = para.text
        node = section
    elif para.style.name == 'Heading 3':
        subsection = etree.SubElement(section, 'subsection')
        text = etree.SubElement(subsection, 'subsectiontext')
        text.text = para.text
        node = subsection
    elif para.style.name.startswith('toc'):
        # We're not interested
        pass
    elif para.style.name == 'Table Grid':
        add_table(para, node)
    elif para.style.name.startswith('Bullets'):
        bullet = etree.SubElement(node, 'bullet')
        bullet.text = para.text
    elif para.text.startswith('Security Control:'):
        if node.tag == 'control':
            node = node.find('..')
        control = etree.SubElement(node, 'control')
        control.text = para.text.strip()
        add_attribs(control)
        control.text = ''       # parsed into attribs
        baseline_control(control, baselines)
        node = control
    elif node is not None:
        '''
        The docx package text properties throw away hyperlinks and just concatenate
        the <w:t> elements together. We want to keep the interspersed <w:hyperlink>
        elements, so have to manage the runs ourselves.

        etree builds the paragraph like:
        <p>
            Some text
            <a href="http://some.link">link display text</a>
            tail text
            <a href="http://another.link">following display text</>
            tail text
        </p>
        '''
        content = etree.SubElement(node, 'p')
        content.text = ''
        add_to_tail = False     # for text following a hyperlink
        for child in para._p:
            text = ''           # initialize in case there's no text
            if isinstance(child, CT_PPr):
                pass
            elif isinstance(child, CT_R):
                # concat the text fragments word creates together
                text = f'{child.text}'
            elif child.tag == HYPERLINK:
                # each hyperlink is a child of the paragraph
                href = etree.SubElement(content, 'a')
                linktext = ''
                for gchild in child:
                    linktext += f'{gchild.text}'
                href.text = linktext
                href.tail = ''
                if args.oscal:
                    href.attrib['href'] = f'#{uuids[child.get(ID)]}'
                else:
                    href.attrib['href'] = rels[child.get(ID)].target_ref
                add_to_tail = True
            if add_to_tail:
                href.tail += text
            else:
                content.text += text

if args.oscal:
    '''
    Add in the back-matter
    '''
    backmatter = etree.SubElement(ism, 'back-matter')

    for key in id_list:
        if isinstance(key, str):    # don't need the toc/internal links
            resource = etree.SubElement(backmatter, 'resource')
            resource.attrib['uuid'] = id_list[key]
            rlink = etree.SubElement(resource, 'rlink')
            rlink.attrib['href'] = key


'''
Finally, write out the output files
'''
with open(args.xmloutfile, 'w') as fh:
    if args.pretty:
        xml = xml.dom.minidom.parseString(etree.tostring(root))
        fh.write(xml.toprettyxml())
    else:
        fh.write(etree.tostring(root, encoding=str))


with open(args.catalogfile, 'w') as fh:
    json.dump(baselines, fh)
