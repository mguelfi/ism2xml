<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://csrc.nist.gov/ns/oscal/1.0" xpath-default-namespace="http://csrc.nist.gov/ns/oscal/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <xsl:output indent="yes" method="xml" encoding="utf-8" omit-xml-declaration="yes" />

  <!-- 'Config' variables -->

  <!-- chapter number prefix for OSCAL -->
  <xsl:variable name="prefix" select="'C'" />
  <!-- control class names -->
  <xsl:variable name="control_class" select="'ISM'" />
  <xsl:variable name="control_test_class" select="'control'" />
  <xsl:variable name="information_class" select="'Information'" />
  <xsl:param name="uuid" />

  <!-- Identity Template -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <!-- Titles Text -->
  <xsl:template match="titletext|sectiontext|subsectiontext">
    <title>
      <xsl:value-of select="." />
    </title>
  </xsl:template>

  <!-- remove wrapping elements -->
  <xsl:template match="root">
    <xsl:apply-templates />
  </xsl:template>

  <!-- OSCAL namespace/uuid support -->
  <xsl:template match="ism">
      <!-- <catalog xmlns="http://csrc.nist.gov/ns/oscal/1.0" uuid="{metadata/@uuid}" xsi:schemaLocation="http://csrc.nist.gov/ns/oscal/1.0 file://oscal-v1.0.xsd"> -->
    <catalog xmlns="http://csrc.nist.gov/ns/oscal/1.0" uuid="{$uuid}" xsi:schemaLocation="http://csrc.nist.gov/ns/oscal/1.0 file://oscal-v1.0.xsd">
      <xsl:apply-templates />
    </catalog>
  </xsl:template>

  <!-- METADATA -->
  <xsl:template match="metadata">
    <metadata>
      <title>Australian Government Information Security Manual</title>
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
      <prop name="keywords" value="assurance, availability, computer security, confidentiality, control" />
    </metadata>
  </xsl:template>

  <!-- remove notes and empty TOC -->
  <xsl:template match="title[not(.//control)]" />

  <!-- chapters -->
  <xsl:template match="title">
    <xsl:for-each select=".">
      <!-- first controls in the ISM are in 'chapter' 2, but TOC is in a title block -->
      <xsl:variable name="chapter" select="count(preceding-sibling::title)-1" />
      <group class="chapter" id="{$prefix}{$chapter}">
        <xsl:apply-templates>
          <xsl:with-param name="chapter" select="$chapter" tunnel="yes" />
        </xsl:apply-templates>
      </group>
    </xsl:for-each>
    <!-- after all the chapters/controls, copy the back-matter in from the source XML -->
    <xsl:copy-of select="back-matter" />
  </xsl:template>

  <!-- section -->
  <xsl:template match="section">
    <xsl:param name="chapter" tunnel="yes" />
    <xsl:variable name="section" select="count(preceding-sibling::section)+1" />
    <xsl:variable name="part_id" select="concat($chapter,'-',$section)" />
    <xsl:variable name="sort_id" select="concat(lower-case($prefix), format-number($chapter, '00'), '-', format-number($section, '00'))" />
    <group class="section" id="{$prefix}{$part_id}">

      <!-- control title -->
      <title>
        <xsl:value-of select="sectiontext" />
      </title>
      <prop name="label" value="{$prefix}{$part_id}" />
      <prop name="sort-id" value="{$sort_id}" />
      <!-- add <link rel="related" href="#uuid> for each URL in the Further information subsection -->
      <xsl:apply-templates select="subsection[subsectiontext = 'Further information']" mode="links" />
      <!-- add in the <control class="ISM"> and <control class="Information"> subsections -->
      <xsl:apply-templates select="subsection">
        <xsl:with-param name="part_id" select="$part_id" tunnel="yes" />
        <xsl:with-param name="sort_id" select="$sort_id" tunnel="yes" />
      </xsl:apply-templates>
    </group>
  </xsl:template>

  <!-- controls -->
  <xsl:template match="subsection">
    <xsl:param name="part_id" tunnel="yes" />
    <xsl:param name="sort_id" tunnel="yes" />
    <xsl:variable name="subsection" select="count(preceding-sibling::subsection[control])+1" />
    <xsl:variable name="control" select="concat($part_id, '.', $subsection)" />
    <xsl:choose>
      <!-- control groups and controls themselves -->
      <xsl:when test="control">
        <control class="{$control_class}" id="{$prefix}{$control}">
          <title>
            <xsl:value-of select="subsectiontext" />
          </title>
          <prop name="label" value="{$prefix}{$control}" />
          <part name="guidance" id="{$prefix}{$control}_gdn">
            <xsl:apply-templates select="p|table|bullet">
              <xsl:with-param name="part_id" select="$control" tunnel="yes" />
            </xsl:apply-templates>
          </part>
          <xsl:apply-templates select="control">
            <xsl:with-param name="part_id" select="$control" tunnel="yes" />
          </xsl:apply-templates>
        </control>
      </xsl:when>
      <!-- preambles and 'Further information' -->
      <xsl:otherwise>
        <!--
      <xsl:when test="subsectiontext = 'Further information'"> -->
        <control class="{$information_class}" id="{$prefix}{$control}">
          <title>
            <xsl:value-of select="subsectiontext" />
          </title>
          <part name="statement" id="{$prefix}{$control}_stm">
            <xsl:apply-templates select="p|table|bullet" />
          </part>
        </control>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- control -->
  <xsl:template match="control">
    <xsl:param name="part_id" tunnel="yes" />
    <xsl:variable name="control" select="count(preceding-sibling::control)+1" />
    <control class="{$control_test_class}" id="{$prefix}{$part_id}.{$control}">
      <title>
        <xsl:value-of select="concat('Security Control: ', @number)"/>
      </title>
      <prop name="number" value="{@number}" />
      <prop name="revision" value="{@revision}" />
      <prop name="update" value="{@update}" />
      <part name="statement" id="{$prefix}{$part_id}.{$control}_stm">
        <xsl:apply-templates select="p|bullet|table" />
      </part>
    </control>
  </xsl:template>
  <xsl:template match="subsection" mode="links">
    <xsl:for-each select="distinct-values(*/a/@href)">
      <link rel="related" href="{.}" />
    </xsl:for-each>
  </xsl:template>

  <!-- Convert bullets to unordered lists -->
  <xsl:template match="bullet">
    <xsl:if test="not(preceding-sibling::*[1][self::bullet])">
      <ul>
        <li>
          <xsl:apply-templates />
        </li>
        <xsl:apply-templates mode="in-list" select="following-sibling::*[1][self::bullet]" />
      </ul>
    </xsl:if>
  </xsl:template>
  <xsl:template match="bullet" mode="in-list">
    <li>
      <xsl:apply-templates />
    </li>
    <xsl:apply-templates mode="in-list" select="following-sibling::*[1][self::bullet]" />
  </xsl:template>
</xsl:stylesheet>
