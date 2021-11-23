<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns="http://csrc.nist.gov/ns/oscal/1.0" xpath-default-namespace="http://csrc.nist.gov/ns/oscal/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <xsl:output indent="yes" method="xml" encoding="utf-8" omit-xml-declaration="yes" />

  <!-- 'Config' variables -->

  <!-- chapter number prefix for OSCAL -->
  <xsl:variable name="prefix" select="'C'" />

  <!-- control class names -->
  <xsl:variable name="control_class" select="'ISM'" />
  <xsl:variable name="control_test_class" select="'TEST'" />
  <xsl:variable name="information_class" select="'Information'" />
  <xsl:param name="classification" />
  <xsl:param name="uuid" />
  <xsl:param name="ism_uuid" />

  <!-- Quash everything not explicity matched -->
  <xsl:template match="@*|node()" />

  <!-- remove wrapping elements -->
  <xsl:template match="root">
    <xsl:apply-templates />
  </xsl:template>

  <!-- OSCAL namespace/uuid support -->
  <xsl:template match="ism">
      <profile xmlns="http://csrc.nist.gov/ns/oscal/1.0" uuid="{$uuid}" xsi:schemaLocation="http://csrc.nist.gov/ns/oscal/1.0 file://oscal-v1.0.xsd">
      <xsl:apply-templates select="metadata" />
      <import href="#{$ism_uuid}">
        <include-controls>
          <xsl:apply-templates select="title" />
        </include-controls>
      </import>
      <xsl:apply-templates select="back-matter" />
    </profile>
  </xsl:template>

  <!-- METADATA -->
  <xsl:template match="metadata">
    <metadata>
      <title>
        <xsl:value-of select="concat('ISM ', upper-case($classification), ' Baseline')" />
      </title>
      <published>
        <xsl:value-of select="format-dateTime(modified, '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01].[f001][Z]')" />
      </published>
      <last-modified>
        <xsl:value-of select="modified" />
      </last-modified>
      <version>
        <xsl:value-of select="version" />
      </version>
      <oscal-version>1.0.0</oscal-version>
    </metadata>
  </xsl:template>

  <!-- remove empty TOC and Using chapter -->
  <xsl:template match="title[parent::ism][not(.//control)]" />

  <!-- chapters -->
  <xsl:template match="title[.//control]">
    <xsl:for-each select=".">

      <!-- first controls in the ISM are in 'chapter' 2, but TOC is in a title block -->
      <xsl:variable name="chapter" select="count(preceding-sibling::title)-1" />
      <xsl:apply-templates>
        <xsl:with-param name="chapter" select="$chapter" tunnel="yes" />
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

  <!-- section -->
  <xsl:template match="section">
    <xsl:param name="chapter" tunnel="yes" />
    <xsl:variable name="section" select="count(preceding-sibling::section)+1" />
    <xsl:variable name="part_id" select="concat($chapter,'-',$section)" />
    <with-id>
      <xsl:value-of select="concat($prefix,$part_id)" />
    </with-id>
    <xsl:apply-templates select="subsection">
      <xsl:with-param name="part_id" select="$part_id" tunnel="yes" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- controls -->
  <xsl:template match="subsection">
    <xsl:param name="part_id" tunnel="yes" />
    <xsl:variable name="subsection" select="count(preceding-sibling::subsection[control])+1" />
    <xsl:variable name="control" select="concat($part_id, '.', $subsection)" />
    <xsl:if test="control/@*[local-name()=$classification]='True'">
      <with-id>
        <xsl:value-of select="concat($prefix,$control)" />
      </with-id>
      <xsl:apply-templates select="control">
        <xsl:with-param name="part_id" select="$control" tunnel="yes" />
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!-- control -->
  <xsl:template match="control">
    <xsl:param name="part_id" tunnel="yes" />
    <xsl:variable name="control" select="count(preceding-sibling::control)+1" />

    <xsl:if test="@*[local-name()=$classification]='True'">
      <xsl:comment><xsl:value-of select="@number"/></xsl:comment>
      <with-id>
        <xsl:value-of select="concat($prefix,$part_id,'.',$control)" />
      </with-id>
    </xsl:if>
  </xsl:template>

  <!-- back-matter -->
  <xsl:template match="back-matter">
    <back-matter>
      <resource uuid="{$ism_uuid}">
        <title>Australian Information Security Manual</title>
        <prop name="version" value="{../metadata/acsc_version}" />
        <rlink media-type="application/xml" href="{fn:iri-to-uri(concat('https://www.cyber.gov.au/sites/default/files/',substring(../metadata/version,1,7),'/Australian Government Information Security Manual ', ../metadata/acsc_version, '.xml'))}" />
      </resource>
    </back-matter>
  </xsl:template>
</xsl:stylesheet>
