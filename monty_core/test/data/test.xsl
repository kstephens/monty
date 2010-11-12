<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exslt="http://exslt.org/common">

<xsl:output method="html"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>

<!-- predeclarations -->


<!-- Entropy File-->
<xsl:variable name="entropy" select="document('entropy.xml')/selectors"/> 
<!--<xsl:variable name="entropy" select="document('http://hubrix.com/entropy.xml')/selectors"/> -->


<!-- Transform Rules -->

<!-- #1. Box(x) -> Change Layout [change bounding box class??]-->
<!-- change_layout(box_xpath, new_layout_class)   -->
<!-- reusable function -->
<xsl:template name="change-layout">
	<xsl:param name="variations"/>
	<xsl:param name="boxentropy"/>
	<xsl:copy>
		<xsl:copy-of select="@*[not(name()='class')]"/><!-- copy the attributes of the box except for class and all the children -->	
		<xsl:for-each select="exslt:node-set($variations)/variant[number(pct) > number($boxentropy)][1]">
			<xsl:sort select="pct" data-type="number" order="ascending"/>
			<xsl:attribute name="class">
				<!--	<xsl:value-of select="."/>-->
				<xsl:value-of select="new-class"/>
			</xsl:attribute>
		</xsl:for-each>
		<xsl:apply-templates select="*"/>
		<xsl:copy-of select="*"><!-- have to add children after attributes -->
	</xsl:copy-of>
	 	</xsl:copy>
</xsl:template>

<!-- function call -->
<xsl:template match="div[@id='content_main']">
	<xsl:call-template name="change-layout">
		<xsl:with-param name="variations">
			<variant>
				<new-class>red horse</new-class>
				<pct>0.73</pct>
			</variant>
			<variant>
				<new-class>blue horse</new-class>
				<pct>0.66</pct>
			</variant>
			<variant>
				<new-class>pink unicorn</new-class>
				<pct>1</pct>
			</variant>
		</xsl:with-param>
		<xsl:with-param name="boxentropy">
			<xsl:value-of select="$entropy/box2"/>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>


<!-- #2. Box(x) -> Change Content [replace contents of box]-->
<!-- change_content(box_xpath, new_content[])   -->
<!-- new_content[]=[[content_1, pct_1], [content_2, pct_2], [content_3]] -->
<!-- reusable function -->
<xsl:template name="change-content">
	<xsl:param name="variations"/>
	<xsl:param name="boxentropy"/>
	<xsl:copy>
		<xsl:copy-of select="@*"/><!-- copy the attributes of the box -->	
		<xsl:for-each select="exslt:node-set($variations)/variant[number(pct) > number($boxentropy)][1]">
			<xsl:sort select="pct" data-type="number" order="ascending"/>
			<xsl:value-of select="content"/>
		</xsl:for-each>
	 	</xsl:copy>
</xsl:template>

<!-- function call -->
<xsl:template match="//*[@id='refer_a_friend']">
	<xsl:call-template name="change-content">
		<xsl:with-param name="variations">
			<variant>
				<content>red horse</content>
				<pct>0.73</pct>
			</variant>
			<variant>
				<content>blue whale</content>
				<pct>0.66</pct>
			</variant>
			<variant>
				<content>green dragon</content>
				<pct>1</pct>
			</variant>
		</xsl:with-param>
		<xsl:with-param name="boxentropy">
			<xsl:value-of select="$entropy/box1"/>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>
	



<!-- #3. Box(x),Box(y) -> Swap [swap contents of boxes]-->
<!-- swap(box_x_xpath, box_y_xpath)   -->
<!-- this one appears impossible to do with a reusable function, i wasted a lot of time on it and wasn't able to do it -->
<!-- template -->
<xsl:param name="x" select="//*[@id='primary_navigation']/*"/> 
<xsl:param name="y" select="//*[@id='preferred_member']/*"/> 
<xsl:template match="//*[@id='preferred_member']">
<xsl:if test="number($entropy/box5) > number(0.5)">
	<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="$x"/>
		</xsl:copy>
</xsl:if>
	</xsl:template>
<xsl:template match="//*[@id='primary_navigation']">
<xsl:if test="number($entropy/box5) > number(0.5)">
	<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="$y"/>
		</xsl:copy>
</xsl:if>
	</xsl:template>		
<!-- #4. Box(x) -> Delete [delete box and contents]-->
<!-- delete(box_xpath)   -->
<xsl:template name="delete">
	<xsl:param name="variations"/>
	<xsl:param name="boxentropy"/>
	<xsl:if test="number($boxentropy) > number($variations)">
		<xsl:copy-of select="."/><!-- basically we copy unless its below the pct, thereby removing it when it is below  the pct-->
	</xsl:if>
</xsl:template>

<!-- function call -->
<xsl:template match="div[@id='featured_media']">
	<xsl:call-template name="delete">
		<xsl:with-param name="variations">
				0.73
		</xsl:with-param>
		<xsl:with-param name="boxentropy">
			<xsl:value-of select="$entropy/box4"/>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>



<!-- #5. Box(x) -> Add Style [add style attribute to box]-->
<!-- add_style(box_xpath, new_style)   -->

<xsl:template name="add-style">
	<xsl:param name="variations"/>
	<xsl:param name="boxentropy"/>
	<xsl:copy>
		<xsl:copy-of select="@*[not(name()='style')]"/><!-- copy the attributes of the box except for class and all the children -->	
		<xsl:for-each select="exslt:node-set($variations)/variant[number(pct) > number($boxentropy)][1]">
			<xsl:sort select="pct" data-type="number" order="ascending"/>
			<xsl:attribute name="style">
				<xsl:value-of select="new-style"/>
				<xsl:value-of select="@style"/>
			</xsl:attribute>
		</xsl:for-each>
		<xsl:apply-templates select="*"/>
		<xsl:copy-of select="*"><!-- have to add children after attributes -->
	</xsl:copy-of>
	 	</xsl:copy>
</xsl:template>

<!-- function call -->
<xsl:template match="div[@id='welcome_message']">
	<xsl:call-template name="add-style">
		<xsl:with-param name="variations">
			<variant>
				<new-style>red shoes</new-style>
				<pct>0.73</pct>
			</variant>
			<variant>
				<new-style>blue socks</new-style>
				<pct>0.66</pct>
			</variant>
			<variant>
				<new-style>pink underwear</new-style>
				<pct>1</pct>
			</variant>
		</xsl:with-param>
		<xsl:with-param name="boxentropy">
			<xsl:value-of select="$entropy/box3"/>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>


<!-- required footer -->
  <xsl:template match="*|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="comment()|processing-instruction()">
    <xsl:copy>.</xsl:copy>
  </xsl:template>
</xsl:stylesheet>

