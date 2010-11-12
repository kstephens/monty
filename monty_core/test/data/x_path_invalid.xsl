<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:exslt="http://exslt.org/common">

  <xsl:template match="#{self.xsl_escape}">
    <xsl:apply-templates select="." />
  </xsl:template>

</xsl:stylesheet>
