<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns="http://www.w3.org/2005/xpath-functions"
                xmlns:oscal="http://csrc.nist.gov/ns/oscal/1.0"
                version="3.0"
                xpath-default-namespace="http://csrc.nist.gov/ns/oscal/1.0"
                exclude-result-prefixes="#all">
   <xsl:output indent="yes" method="text" use-character-maps="delimiters"/>
   <!-- METASCHEMA conversion stylesheet supports XML->JSON conversion -->
   <!-- 88888888888888888888888888888888888888888888888888888888888888 -->
   <xsl:character-map name="delimiters">
      <xsl:output-character character="&lt;" string="\u003c"/>
      <xsl:output-character character="&gt;" string="\u003e"/>
   </xsl:character-map>
   <xsl:param name="json-indent" as="xs:string">no</xsl:param>
   <xsl:mode name="rectify" on-no-match="shallow-copy"/>
   <xsl:template mode="rectify"
                 xpath-default-namespace="http://www.w3.org/2005/xpath-functions"
                 match="/*/@key | array/*/@key"/>
   <xsl:variable name="write-options" as="map(*)" expand-text="true">
      <xsl:map>
         <xsl:map-entry key="'indent'">{ $json-indent='yes' }</xsl:map-entry>
      </xsl:map>
   </xsl:variable>
   <xsl:template match="/" mode="debug">
      <xsl:apply-templates mode="xml2json"/>
   </xsl:template>
   <xsl:template match="/">
      <xsl:variable name="xpath-json">
         <xsl:apply-templates mode="xml2json"/>
      </xsl:variable>
      <xsl:variable name="rectified">
         <xsl:apply-templates select="$xpath-json" mode="rectify"/>
      </xsl:variable>
      <json>
         <xsl:value-of select="xml-to-json($rectified, $write-options)"/>
      </json>
   </xsl:template>
   <xsl:template name="prose">
      <xsl:if test="exists(p | ul | ol | pre)">
         <array key="prose">
            <xsl:apply-templates mode="md" select="p | ul | ol | pre"/>
         </array>
      </xsl:if>
   </xsl:template>
   <xsl:template mode="as-string" match="@* | *">
      <xsl:param name="key" select="local-name()"/>
      <xsl:if test="matches(.,'\S')">
         <string key="{$key}">
            <xsl:value-of select="."/>
         </string>
      </xsl:if>
   </xsl:template>
   <xsl:template mode="md" match="p | link | part/*">
      <string>
         <xsl:apply-templates mode="md"/>
      </string>
   </xsl:template>
   <xsl:template mode="md" priority="1" match="pre">
      <string>```</string>
      <string>
         <xsl:apply-templates mode="md"/>
      </string>
      <string>```</string>
   </xsl:template>
   <xsl:template mode="md" priority="1" match="ul | ol">
      <string/>
      <xsl:apply-templates mode="md"/>
      <string/>
   </xsl:template>
   <xsl:template mode="md" match="ul//ul | ol//ol | ol//ul | ul//ol">
      <xsl:apply-templates mode="md"/>
   </xsl:template>
   <xsl:template mode="md" match="li">
      <string>
         <xsl:for-each select="../ancestor::ul">
            <xsl:text/>
         </xsl:for-each>
         <xsl:text>* </xsl:text>
         <xsl:apply-templates mode="md"/>
      </string>
   </xsl:template>
   <xsl:template mode="md" match="ol/li">
      <string/>
      <string>
         <xsl:for-each select="../ancestor::ul">
            <xsl:text/>
         </xsl:for-each>
         <xsl:text>1. </xsl:text>
         <xsl:apply-templates mode="md"/>
      </string>
   </xsl:template>
   <xsl:template mode="md" match="code | span[contains(@class,'code')]">
      <xsl:text>`</xsl:text>
      <xsl:apply-templates mode="md"/>
      <xsl:text>`</xsl:text>
   </xsl:template>
   <xsl:template mode="md" match="em | i">
      <xsl:text>*</xsl:text>
      <xsl:apply-templates mode="md"/>
      <xsl:text>*</xsl:text>
   </xsl:template>
   <xsl:template mode="md" match="strong | b">
      <xsl:text>**</xsl:text>
      <xsl:apply-templates mode="md"/>
      <xsl:text>**</xsl:text>
   </xsl:template>
   <xsl:template mode="md" match="q">
      <xsl:text>"</xsl:text>
      <xsl:apply-templates mode="md"/>
      <xsl:text>"</xsl:text>
   </xsl:template>
   <xsl:key name="element-by-id" match="*[exists(@id)]" use="@id"/>
   <xsl:template mode="md" match="a[starts-with(@href,'#')]">
      <xsl:variable name="link-target"
                    select="key('element-by-id',substring-after(@href,'#'))"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="replace(.,'&lt;','&amp;lt;')"/>
      <xsl:text>]</xsl:text>
      <xsl:text>(#</xsl:text>
      <xsl:value-of select="$link-target/*[1] =&gt; normalize-space() =&gt; lower-case() =&gt; replace('\s+','-') =&gt; replace('[^a-z\-\d]','')"/>
      <xsl:text>)</xsl:text>
   </xsl:template>
   <xsl:template match="text()" mode="md">
      <xsl:value-of select="replace(.,'\s+',' ') ! replace(.,'([`~\^\*])','\$1')"/>
   </xsl:template>
   <!-- 88888888888888888888888888888888888888888888888888888888888888 -->
   <xsl:template match="profile" mode="xml2json">
      <map key="profile">
         <xsl:if test="exists(import)">
            <array key="imports">
               <xsl:apply-templates select="import" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:apply-templates select="merge" mode="#current"/>
         <xsl:apply-templates select="modify" mode="#current"/>
      </map>
   </xsl:template>
   <xsl:template match="import" mode="xml2json">
      <map key="import">
         <xsl:apply-templates select="include" mode="#current"/>
         <xsl:apply-templates select="exclude" mode="#current"/>
      </map>
   </xsl:template>
   <xsl:template match="merge" mode="xml2json">
      <map key="merge">
         <xsl:apply-templates select="combine" mode="#current"/>
         <xsl:apply-templates select="as-is" mode="#current"/>
         <xsl:apply-templates select="custom" mode="#current"/>
      </map>
   </xsl:template>
   <xsl:template match="combine" mode="xml2json">
      <map key="combine">
         <xsl:apply-templates mode="as-string" select="@method"/>
         <xsl:apply-templates mode="as-string" select=".">
            <xsl:with-param name="key">STRVALUE</xsl:with-param>
         </xsl:apply-templates>
      </map>
   </xsl:template>
   <xsl:template match="as-is" mode="xml2json">
      <string key="as-is">As isAn As-is element indicates that the controls should be structured in resolution as they are
        structured in their source catalogs. It does not contain any elements or attributes.</string>
   </xsl:template>
   <xsl:template match="custom" mode="xml2json">
      <map key="custom">
         <xsl:if test="exists(group)">
            <array key="groups">
               <xsl:apply-templates select="group" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(call)">
            <array key="id-selectors">
               <xsl:apply-templates select="call" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(match)">
            <array key="pattern-selectors">
               <xsl:apply-templates select="match" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="group" mode="xml2json">
      <map key="group">
         <xsl:if test="exists(group)">
            <array key="groups">
               <xsl:apply-templates select="group" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(call)">
            <array key="id-selectors">
               <xsl:apply-templates select="call" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(match)">
            <array key="pattern-selectors">
               <xsl:apply-templates select="match" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="modify" mode="xml2json">
      <map key="modify">
         <xsl:if test="exists(set-param)">
            <array key="param-settings">
               <xsl:apply-templates select="set-param" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(alter)">
            <array key="alterations">
               <xsl:apply-templates select="alter" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="include" mode="xml2json">
      <map key="include">
         <xsl:apply-templates select="all" mode="#current"/>
         <xsl:if test="exists(call)">
            <array key="id-selectors">
               <xsl:apply-templates select="call" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(match)">
            <array key="pattern-selectors">
               <xsl:apply-templates select="match" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="all" mode="xml2json">
      <map key="all">
         <xsl:apply-templates mode="as-string" select="@with-subcontrols"/>
         <xsl:apply-templates mode="as-string" select=".">
            <xsl:with-param name="key">STRVALUE</xsl:with-param>
         </xsl:apply-templates>
      </map>
   </xsl:template>
   <xsl:template match="call" mode="xml2json">
      <map key="call">
         <xsl:apply-templates mode="as-string" select="@control-id"/>
         <xsl:apply-templates mode="as-string" select="@subcontrol-id"/>
         <xsl:apply-templates mode="as-string" select="@with-control"/>
         <xsl:apply-templates mode="as-string" select="@with-subcontrols"/>
         <xsl:apply-templates mode="as-string" select=".">
            <xsl:with-param name="key">STRVALUE</xsl:with-param>
         </xsl:apply-templates>
      </map>
   </xsl:template>
   <xsl:template match="match" mode="xml2json">
      <map key="match">
         <xsl:apply-templates mode="as-string" select="@pattern"/>
         <xsl:apply-templates mode="as-string" select="@order"/>
         <xsl:apply-templates mode="as-string" select="@with-control"/>
         <xsl:apply-templates mode="as-string" select="@with-subcontrols"/>
         <xsl:apply-templates mode="as-string" select=".">
            <xsl:with-param name="key">STRVALUE</xsl:with-param>
         </xsl:apply-templates>
      </map>
   </xsl:template>
   <xsl:template match="exclude" mode="xml2json">
      <map key="exclude">
         <xsl:if test="exists(call)">
            <array key="id-selectors">
               <xsl:apply-templates select="call" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(match)">
            <array key="pattern-selectors">
               <xsl:apply-templates select="match" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="set-param" mode="xml2json">
      <map key="{@id}">
         <xsl:apply-templates mode="as-string" select="@id"/>
         <xsl:apply-templates mode="as-string" select="@class"/>
         <xsl:apply-templates mode="as-string" select="@depends-on"/>
         <xsl:apply-templates select="label" mode="#current"/>
         <xsl:if test="exists(desc)">
            <array key="descriptions">
               <xsl:apply-templates select="desc" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(constraint)">
            <array key="constraints">
               <xsl:apply-templates select="constraint" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:apply-templates select="value" mode="#current"/>
         <xsl:apply-templates select="select" mode="#current"/>
         <xsl:if test="exists(link)">
            <array key="links">
               <xsl:apply-templates select="link" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(part)">
            <array key="parts">
               <xsl:apply-templates select="part" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="alter" mode="xml2json">
      <map key="alter">
         <xsl:apply-templates mode="as-string" select="@control-id"/>
         <xsl:apply-templates mode="as-string" select="@subcontrol-id"/>
         <xsl:if test="exists(remove)">
            <array key="removals">
               <xsl:apply-templates select="remove" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(add)">
            <array key="additions">
               <xsl:apply-templates select="add" mode="#current"/>
            </array>
         </xsl:if>
      </map>
   </xsl:template>
   <xsl:template match="remove" mode="xml2json">
      <map key="remove">
         <xsl:apply-templates mode="as-string" select="@class-ref"/>
         <xsl:apply-templates mode="as-string" select="@id-ref"/>
         <xsl:apply-templates mode="as-string" select="@item-name"/>
         <xsl:apply-templates mode="as-string" select=".">
            <xsl:with-param name="key">STRVALUE</xsl:with-param>
         </xsl:apply-templates>
      </map>
   </xsl:template>
   <xsl:template match="add" mode="xml2json">
      <map key="add">
         <xsl:apply-templates mode="as-string" select="@position"/>
         <xsl:apply-templates select="title" mode="#current"/>
         <xsl:for-each-group select="param" group-by="local-name()">
            <map key="params">
               <xsl:apply-templates select="current-group()" mode="#current"/>
            </map>
         </xsl:for-each-group>
         <xsl:if test="exists(prop)">
            <array key="props">
               <xsl:apply-templates select="prop" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(link)">
            <array key="links">
               <xsl:apply-templates select="link" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:if test="exists(part)">
            <array key="parts">
               <xsl:apply-templates select="part" mode="#current"/>
            </array>
         </xsl:if>
         <xsl:apply-templates select="references" mode="#current"/>
      </map>
   </xsl:template>
</xsl:stylesheet>
