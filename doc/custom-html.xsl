<?xml version="1.0" encoding="US-ASCII"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

   <xsl:import
       href="http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl"/>

  <!--- Number sections -->
  <xsl:param name="section.autolabel" select="1"/>
  <xsl:param name="section.label.includes.component.label" select="1"/>

  <!-- Use shade for verbatim environments -->
  <xsl:param name="shade.verbatim" select="1"></xsl:param>

  <xsl:param name="html.stylesheet">susebooks.css</xsl:param>

</xsl:stylesheet>
