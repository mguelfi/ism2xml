import sys
import argparse
import re
import json
import xml.dom.minidom
from lxml import etree
from pathlib import Path
from uuid import uuid4
from time import localtime, strftime

parser = argparse.ArgumentParser(description='Make basic profiles from baselines.json')
parser.add_argument('-b', '--baselines', dest='baselines', default='baselines.json', help='path to the baselines file')
parser.add_argument('-p', '--pretty', dest='pretty', action='store_true', help='pretty print the output')
parser.add_argument('-o', '--output', dest='output', default='ISM', help='output file path/prefix')
parser.add_argument('-v', '--version', dest='version', default='ism-oscal1.0.0', help='profile version')
args = parser.parse_args()

if not Path(args.baselines).is_file():
    print('{} is not a file'.format(args.baselines))
    sys.exit(1)

with open(args.baselines) as fh:
    base = json.load(fh)

published = strftime("%Y-%m-%dT%H:%M:%S.000%z", localtime())


for key in base:
    root = etree.Element('profile')
    root.attrib['xmlns']="http://csrc.nist.gov/ns/oscal/1.0"
    root.attrib['uuid']=str(uuid4())

    meta = etree.SubElement(root, 'metadata')

    etree.SubElement(meta, 'title').text = f'ISM {key.capitalize()} Baseline'
    etree.SubElement(meta, 'published').text = f'{published}'
    etree.SubElement(meta, 'last-modified').text = f'{published}'
    etree.SubElement(meta, 'version').text = f'{args.version}'
    etree.SubElement(meta, 'oscal-version').text = '1.0.0'


    print(etree.tostring(root, encoding=str))
    sys.exit(0)
