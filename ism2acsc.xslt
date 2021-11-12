<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.xx.com" xpath-default-namespace="http://csrc.nist.gov/ns/oscal/1.0" xmlns:fn="http://www.fn.com" exclude-result-prefixes="xsd fn">
    <xsl:output indent="yes" method="xml" encoding="utf-8" omit-xml-declaration="no" standalone="yes"/>
  <xsl:function name="fn:true2yes">
    <xsl:param name="val" />
    <xsl:choose>
      <xsl:when test="$val != 'False'">
        <text>Yes</text>
      </xsl:when>
      <xsl:otherwise>
        <text>No</text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- remove wrapping elements -->

  <!-- <xsl:template match="ism">
  <xsl:apply-templates />
  </xsl:template> -->
  <xsl:template match="root">
    <xsl:comment> <xsl:value-of select="ism/metadata/acsc_version"/> </xsl:comment>
    <ISM>
      <xsl:apply-templates />
    </ISM>
  </xsl:template>
  <xsl:template match="title|metadata|titletext|sectiontext">
    <xsl:if test=".//control">
      <xsl:apply-templates />
    </xsl:if>
  </xsl:template>
  <xsl:template match="p">
    <xsl:value-of select="." />

    <!-- <xsl:text>&#xa;</xsl:text> -->
  </xsl:template>
  <xsl:template match="subsection">
    <xsl:apply-templates select="control" />
  </xsl:template>
  <xsl:template match="bullet">
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="concat('• ', .)" />
  </xsl:template>

  <xsl:template match="table"> (see source document for referenced table)</xsl:template>

  <!-- Controls -->
  <xsl:template match="control">
    <xsl:element name="Control">
      <Guideline>
        <xsl:value-of select="ancestor::title/titletext" />
      </Guideline>
      <Section>
        <xsl:value-of select="ancestor::section/sectiontext" />
      </Section>
      <Topic>
        <xsl:value-of select="parent::subsection/subsectiontext" />
      </Topic>
      <Identifier>
        <xsl:value-of select="@number" />
      </Identifier>
      <Revision>
        <xsl:value-of select="@revision" />
      </Revision>
      <Updated>
        <xsl:value-of select="@update" />
      </Updated>
      <OFFICIAL>
        <xsl:value-of select="fn:true2yes(@official)" />
      </OFFICIAL>
      <PROTECTED>
        <xsl:value-of select="fn:true2yes(@protected)" />
      </PROTECTED>
      <SECRET>
        <xsl:value-of select="fn:true2yes(@secret)" />
      </SECRET>
      <TOP_SECRET>
        <xsl:value-of select="fn:true2yes(@top_secret)" />
      </TOP_SECRET>
      <Description>
        <xsl:apply-templates select="p|bullet|table" />
      </Description>
    </xsl:element>
  </xsl:template>

  <!-- -->
</xsl:stylesheet>
