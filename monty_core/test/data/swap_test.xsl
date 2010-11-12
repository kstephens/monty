<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exslt="http://exslt.org/common">

  <xsl:output method="html"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" />

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()">
    <xsl:copy>.</xsl:copy>
  </xsl:template>

  <!-- Rule swap content of *[@id='3'] with *[@id='4'] -->
  <xsl:template match="*[@id='3']">
       <xsl:copy> 
          <xsl:apply-templates select="@*" />
	  <xsl:apply-templates select="//*[@id='4']/node()" />
        </xsl:copy>
  </xsl:template>

  <!-- Rule swap content of *[@id='3'] with *[@id='4'] -->
  <xsl:template match="*[@id='4']">
       <xsl:copy> 
          <xsl:apply-templates select="@*" />
	  <xsl:apply-templates select="//*[@id='3']/node()" />
        </xsl:copy>
  </xsl:template>

<!-- footer -->
</xsl:stylesheet>
