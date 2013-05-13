<cfcomponent>
	<!--- 
	add support for css "background:"
	add support for @import - currently it is just reinserted and the contents of the imported css file are not parsed.
	
	// you can avoid non-repeating background images from going in the sprite map by using background-repeat:no-repeat !important;
	 --->
	<cfoutput>
    
	<cffunction name="init" access="public" output="no">
    	<cfargument name="config" type="struct" required="yes">
        <cfscript>
		var root=expandPath("/");
		this.config={
			charset:"utf-8",
			spritePad:1,
			disableMinify:false,
			jpegFilePath:root&"/cssSpriteMap.jpg",
			pngFilePath:root&"/cssSpriteMap.png",
			jpegRootRelativePath:"/cssSpriteMap.jpg",
			pngRootRelativePath:"/cssSpriteMap.png",
			disableSpriteMap:false,
			root:root,
		};
		structappend(this, this.config, true);
		aliasStruct={"/":root};
		structappend(this, arguments.config, true);
		variables.initRun=true;
        </cfscript>
    </cffunction>


    <cffunction name="saveCSS" returntype="boolean" access="public" output="false">
        <cfargument name="filePath" required="yes" type="string">
        <cfargument name="srcString" required="yes" type="string">
        <cfscript>
        var tempUnique='###getTickCount()#';
        </cfscript>
        <cfif arguments.filePath NEQ "">
            <cftry>
                <cffile addnewline="no" action="write" nameconflict="overwrite" charset="utf-8" file="#arguments.filePath##tempUnique#" output="#arguments.srcString#">
                <cfif compare(arguments.filePath&tempUnique , arguments.filePath) NEQ 0>
                    <cflock name="cssSpriteMap|#arguments.filePath#" timeout="60" type="exclusive">
                        <cffile action="rename" nameconflict="overwrite" source="#arguments.filePath##tempUnique#" destination="#arguments.filePath#">
                    </cflock>
                </cfif>
                <cfcatch type="any">
					<cfscript>
                    throw('Failed to save css. arguments.filePath=#arguments.path#',true);
                    </cfscript>
            	</cfcatch>
            </cftry>
        <cfelse>
            <cfscript>
            throw('Failed to save css. arguments.filePath=#arguments.path#',true);
            </cfscript>
        </cfif>
        <cfreturn true>
    </cffunction>
    
	<cffunction name="setCSSRoot" access="public" output="no">
    	<cfargument name="rootPath" type="string" required="yes">
    	<cfargument name="rootRelativePath" type="string" required="yes">
        <cfscript>
		variables.cssRootPath=arguments.rootPath;
		variables.cssRootRelativePath=arguments.rootRelativePath;
		</cfscript>
    </cffunction>
    
	<cffunction name="loadCSSFile" access="public" output="no">
    	<cfargument name="cssFilePath" type="string" required="yes">
    	<cfargument name="cssRootRelativePath" type="string" required="yes">
    	<cfscript>
		var css=0;
		variables.cssRootPath=getdirectoryfrompath(arguments.cssFilePath);
		if(arguments.cssFilePath  EQ  ""  OR  replace(arguments.cssFilePath, "./", "", "all") NEQ arguments.cssFilePath  OR  mid(arguments.cssFilePath, len(arguments.cssFilePath)-3,4) NEQ ".css" or not fileexists(arguments.cssFilePath)){
			throw("All CSS file in the array must end with .css and be an absolute path.","all");
		}
		local.fileHandle=fileopen(arguments.cssFilePath, "read", "utf-8");
		css=replace(replace(fileread(local.fileHandle), chr(10), " ", "all"), chr(13),"", "all");
		fileclose(local.fileHandle);
		return css;
		</cfscript>
    </cffunction>
    
    
    <!--- cssSpriteMap.loadCSSFileArray([{absolutePath:"",relativePath:""}]; --->
    <cffunction name="loadCSSFileArray" output="no" access="public">
    	<cfargument name="arrCSSFile" type="array" required="yes">
        <cfscript>
		var local={};
		var e=0;
		var a=0;
		local.arrCSS=[];
		for(local.i=1;local.i LTE arraylen(arguments.arrCSSFile);local.i++){
			a=arguments.arrCSSFile[local.i].absolutePath;
			if(a  EQ  ""  OR  replace(a, "./", "", "all") NEQ a  OR  mid(a, len(a)-3,4) NEQ ".css" or not fileexists(a)){
				throw("All CSS file in the array must end with .css and be an absolute path.","all");
			}
			try{
				arrayappend(local.arrCSS, '@@z@@'&a&'~'&arguments.arrCSSFile[local.i].relativePath&'@'&fileread(a, this.charset));
			}catch(Any e){
				throw("CSS File doesn't exist: "&a, "custom");
			}
		}
		return arraytolist(local.arrCSS, chr(10));
		</cfscript>
    </cffunction>
    
	<cffunction name="convertAndReturnCSS" access="public" returntype="struct" output="yes">
    	<cfargument name="css" type="string" required="yes">
    	<cfscript>
		var local={};
		if(not structkeyexists(variables,'initRun')){
			this.init();
		}
		if(not structkeyexists(variables,'cssRootPath') or variables.cssRootPath EQ ""){
			throw("cssSpriteMap.setCSSRoot() must be called before cssSpriteMap.convertAndReturnCSS()", "custom");
		}
		if(trim(arguments.css) EQ ""){
			throw("this.css must be set before calling convert.", "custom");
		}
		variables.arrAlias=structkeyarray(this.aliasStruct);
		arraysort(variables.arrAlias, "text", "desc");
		local.arrCSS=variables.parseCSSString(arguments.css);
		local.rs=variables.getImagesFromParsedCSS(local.arrCSS);
		local.rs=variables.generateSpriteMaps(rs);
		local.s=variables.rebuildCSS(local.arrCSS, local.rs);
		return { arrCSS:local.arrCSS, cssStruct:local.rs, css:local.s};
		</cfscript>
    </cffunction>



	<cffunction name="displayCSS" access="public" output="yes">
    	<cfargument name="arrCSS" type="array" required="yes">
    	<cfargument name="imageStruct" type="struct" required="yes">
    	<cfscript>
		local.html="<h2>Use the CSS class names below in your code</h2>";
		local.css="";
		local.css2="";
		local.cssPrefix="sn-";
		local.count=0;
		for(local.key=1;local.key LTE arraylen(arguments.arrCSS);local.key++){
			local.curValue=arguments.arrCSS[local.key];
			if(local.curValue.type  EQ  "rules"){
				for(local.i=1;local.i LTE arraylen(local.curValue.arrProperty);local.i++){
					local.c=local.curValue.arrProperty[local.i];
					if(local.c.name  EQ  "background-image"){
						if(this.disableSpritemap EQ 0){
							local.match=false;
							if(structkeyexists(local.c, 'imageIndex') and local.c.imageIndex GT 0){
								local.match=true;
								local.curSpriteFile=this.jpegRootRelativePath;
								local.ts=arguments.imageStruct.imageStruct[arguments.imageStruct.arrLookupImage[local.c.imageIndex]];
							}else if(structkeyexists(local.c, 'transparentIndex') and local.c.transparentIndex GT 0){
								local.match=true;
								local.curSpriteFile=this.pngRootRelativePath;
								local.ts=arguments.imageStruct.imageTransparentStruct[arguments.imageStruct.arrLookupTransparent[local.c.transparentIndex]];
							}
							if(local.match){
								if(local.ts.selector NEQ ""){
									local.t9=listtoarray(local.ts.selector, "{");
									local.className=local.t9[1];
								}else{
									local.className=local.cssPrefix&local.count;//"";
								}
								local.count++;
								local.tempClass="."&local.cssPrefix&local.count;
								local.c444=' class="'&local.cssPrefix&local.count&'"';
								local.html&='<h2>'&local.className&'</h2> <div style="width:'&local.ts.width&'px; height:'&local.ts.height&'px;  margin-bottom:10px; clear:both;" '&local.c444&'></div><hr />';
								local.css&=""&local.className&"{width:"&local.ts.width&"px; height:"&local.ts.height&"px; background-image:url("&local.curSpriteFile&"); background-position:"&(local.ts.left-this.spritePad)&"px "&(local.ts.top-this.spritePad)&"px; background-repeat:no-repeat; } "&chr(10);
								local.css2&=""&local.tempClass&"{width:"&local.ts.width&"px; height:"&local.ts.height&"px; background-image:url("&local.curSpriteFile&"); background-position:"&(local.ts.left-this.spritePad)&"px "&(local.ts.top-this.spritePad)&"px; background-repeat:no-repeat; } "&chr(10);
							}
							
						}
					}
				}
			}
		}
		writeoutput('<html><head><title>CSS Sprite Map Generator</title><style type="text/css">'&local.css2&'</style></head><body style="margin:10px;"><h1>CSS Sprite Map Generator</h1>');
		if(local.count){
			writeoutput('<p>Sprite map image(s) were created from all images with "background-repeat:no-repeat" or "background:##FFF url(image.jpg) no-repeat" shorthand in the CSS. To prevent an image from being in the sprite map, use "background-repeat:no-repeat !important;".</p>');
			writeoutput('<div style="width:100%; "><h2>JPEG Sprite Map</h2><img src="'&this.jpegRootRelativePath&'" style="border:2px solid ##999;" alt="JPEG Sprite Map" /></div>');
			writeoutput('<div style="width:100%; "><h2>PNG Sprite Map (Preserves Alpha Channel Transparency)</h2><img src="'&this.pngRootRelativePath&'" style="border:2px solid ##999;" alt="PNG Sprite Map" /></div>');
			writeoutput('<h2>CSS Styles Generated</h2> <div style="width:100%; "><textarea name="d11" id="d11" cols="90" rows="10">'&local.css&'</textarea><br />'&local.html&'</div>');
		}else{
			writeoutput('<p>No images could be converted into a css sprite map.</p>');	
		}
		writeoutput('</body></html>');
		</cfscript>
    </cffunction>
    
    <!--- private methods below --->
    
    <cffunction name="forceAbsoluteDir" access="private" output="yes" returntype="string">
        <cfargument name="path" type="string" required="yes">
        <cfargument name="filePath" type="string" required="yes">
        <cfargument name="rootPath" type="string" required="yes">
        <cfscript>
		var local={};
		var arrN=[];
		if(mid(arguments.path,1,1) EQ "/"){
			arguments.path=arguments.rootPath&removechars(arguments.path,1,1);
		}else{
			arguments.path=arguments.filePath&arguments.path;
		}
		local.arr3=listtoarray(arguments.rootPath, "/");
		local.arrN2=[];
		local.count3=arraylen(local.arr3)
		for(local.i2=1;local.i2 LTE local.count3;local.i2++){
			if(local.arr3[local.i2] NEQ ""){
				arrayappend(local.arrN2, local.arr3[local.i2]);	
			}
		}
		local.arr2=listtoarray(arguments.path, "/");
		local.count=arraylen(local.arr2);
		for(local.i2=1;local.i2 LTE local.count;local.i2++){
			local.c2=local.arr2[local.i2];	
			if(local.c2 EQ ""){
				continue;	
			}else if(local.c2 EQ "."){
				continue;
			}else if(local.c2 EQ ".."){
				if(arraylen(local.arrN) GT arraylen(local.arrN2)-1){
					arraydeleteat(local.arrN, arraylen(local.arrN));
				}
			}else{
				arrayappend(local.arrN, local.c2);	
			}
		}
		return "/"&arraytolist(local.arrN, "/");
		</cfscript>
    </cffunction>
    
    <cffunction name="indexAscending" access="private" output="no">
        <cfargument name="a" type="any" required="yes">
        <cfargument name="b" type="any" required="yes">
        <cfscript>
        if(arguments.a.curIndex EQ  arguments.b.curIndex){
            return 0 ; 
        }
        if(arguments.a.curIndex LT arguments.b.curIndex){
            return -1;
        }else{
            return 1;
        }
        </cfscript>
    </cffunction>
    <cffunction name="widthDescending" access="private" output="no">
        <cfargument name="a" type="any" required="yes">
        <cfargument name="b" type="any" required="yes">
        <cfscript>
        if(arguments.a.width EQ  arguments.b.width){
            return 0 ; 
        }
        if(arguments.a.width GT arguments.b.width){
            return -1;
        }else{
            return 1;
        }
        </cfscript>
    </cffunction>
    <cffunction name="widthDescending" access="private" output="no">
        <cfargument name="a" type="any" required="yes">
        <cfargument name="b" type="any" required="yes">
        <cfscript>
        if(arguments.a.height EQ  arguments.b.height){
            return 0 ; 
        }
        if(arguments.a.height GT arguments.b.height){
            return -1;
        }else{
            return 1;
        }
        </cfscript>
    </cffunction>

    <cffunction name="generateSpriteMap" access="private" output="no">
        <cfargument name="arrImage2" type="array" required="yes">
        <cfargument name="spriteMapFile" type="string" required="yes">
        <cfscript>
        var local=structnew();
        var imageCount=arraylen(arguments.arrImage2);
		var transparent=false;
		var uniqueStruct={};
		if(not imageCount) return arguments.arrImage2;
        local.imageStruct={};
        for(local.i=1;local.i LTE imageCount;local.i++){
            local.arrTemp=listtoarray(arguments.arrImage2[local.i], "?");
            local.curPath9=local.arrTemp[1];
			if(structkeyexists(uniqueStruct, local.curPath9)){
				local.ts={};
				local.ts.selector="";
				local.ts.top=0;
				local.ts.left=0;
                local.ts.curIndex=local.i;
				local.ts.referenceIndex=uniqueStruct[local.curPath9];
				local.ts.width=0;
				local.ts.height=0;
                local.ts.image=local.arrTemp[1];
                local.imageStruct[local.i]=local.ts;
				continue;
			}
            local.r=imageread(local.curPath9);
            if(isStruct(local.r)){
                local.ts={};
				local.ts.source=local.r;
                local.ts.curIndex=local.i;
				local.ts.selector="";
                local.ts.left=0;
                local.ts.top=0;
                local.ts.width=local.r.width+(this.spritePad*2);
                local.ts.height=local.r.height+(this.spritePad*2);
                local.ts.image=local.arrTemp[1];
                
                local.ext=mid(local.arrTemp[1], len(local.arrTemp[1])-3,4);
				if(local.ext EQ ".png" or local.ext EQ ".gif"){
					transparent=true;
				}
                local.ts.ext=local.ext;
                local.imageStruct[local.i]=local.ts;
            }else{
                local.ts={};
                local.ts.width=0;
                local.ts.height=0;
                local.ts.left=0;
                local.ts.top=0;
                local.ts.curIndex=local.i;
                local.imageStruct[local.i]=local.ts;
            }
			uniqueStruct[local.curPath9]=local.i;
        }
		
        local.arrKey=structsort(local.imageStruct, "numeric", "desc", "width");
        local.maxImageWidth=local.imageStruct[local.arrKey[1]].width;
        
        local.arrKey=structsort(local.imageStruct, "numeric", "desc", "height");
        local.maxWidth=local.maxImageWidth;
        local.curX=0;
        local.curY=0;
        local.nextY=0;
        local.arrGrid=[];
        local.imagePad=1;
        
        local.maxWidthDivided=ceiling(local.maxWidth/local.imagePad);
        local.maxHeightDivided=ceiling(10000/local.imagePad);
        
        local.maxHeight=0;
        local.maxWidth=0;
        for(local.g=1;local.g LTE local.imageCount;local.g++){
            local.ts=local.imageStruct[local.arrKey[local.g]];
            if(local.ts.width  EQ  0){continue; }
            local.searching=true;
            local.curX=0;
            local.curY=0;
            local.tsWidthDivided=ceiling(local.ts.width/local.imagePad);
            local.tsHeightDivided=ceiling(local.ts.height/local.imagePad);
            local.arrRowHeights=[];
            for(local.n=0;local.n LT local.maxHeightDivided;local.n++){
                for(local.i=0;local.i LTE local.maxWidthDivided-local.tsWidthDivided;local.i++){
                    // do hit detection on all the previous sprites
                    local.hit=false;
					for(local.f=1;local.f LTE arraylen(local.arrKey);local.f++){
						local.curObj=local.imageStruct[local.arrKey[local.f]];
                        local.curObj=local.imageStruct[local.f];
                        if(structkeyexists(local.curObj, 'leftDivided') and local.i+local.tsWidthDivided gt local.curObj.leftDivided and local.i lt local.curObj.rightDivided and local.n+local.tsHeightDivided gt local.curObj.topDivided and local.n lt local.curObj.bottomDivided){
                            local.hit=true;
                            local.i=local.curObj.rightDivided-1;
                            break;
                        }
                    }
                    if(local.hit){
                        continue;
                    }else{
                        local.curX=local.i;
                        local.curY=local.n;
                        local.searching=false;	
                        break;
                    }
                }
                if(local.searching EQ false){
                    break;
                }
            }
            local.ts.left=local.curX*local.imagePad;
            local.ts.top=local.curY*local.imagePad;
            local.ts.right=local.ts.left+local.ts.width;
            local.ts.bottom=local.ts.top+local.ts.height;
            local.maxHeight=max(local.ts.bottom, local.maxHeight);
            local.maxWidth=max(local.ts.right, local.maxWidth);
            local.ts.leftDivided=ceiling(local.ts.left/local.imagePad);
            local.ts.topDivided=ceiling(local.ts.top/local.imagePad);
            local.ts.rightDivided=ceiling(local.ts.right/local.imagePad);
            local.ts.bottomDivided=ceiling(local.ts.bottom/local.imagePad);
        }
        if(transparent){
        	local.finalImage = imagenew("", local.maxWidth, local.maxHeight, "argb");
        }else{
        	local.finalImage = imagenew("", local.maxWidth, local.maxHeight, "rgb", "##FFFFFF");
        }
		ImageSetAntialiasing(local.finalImage,"on");
        for(local.i in local.imageStruct){
            if(local.imageStruct[local.i].width  EQ  0) continue;
            local.ts=local.imageStruct[local.i];
            local.ts.width-=(this.spritePad*2);
            local.ts.height-=(this.spritePad*2);
			ImagePaste(local.finalImage, local.ts.source, local.ts.left+this.spritePad, local.ts.top+this.spritePad);
			structdelete(local.ts, 'source');
        }
        if(local.ext EQ ".png"){
			imagewrite(local.finalImage, arguments.spriteMapFile, true, 5);
        }else{
			imagewrite(local.finalImage, arguments.spriteMapFile, true, 90);
        }        
        return local.imageStruct;
        </cfscript>
    </cffunction>

    
    
    <cffunction name="parseCSSString" access="private" output="no">
        <cfargument name="css" type="string" required="yes">
		<cfscript>
		var local={};
		arguments.css=replace(arguments.css, chr(13), "","all");
        local.length=len(arguments.css);
        local.inComment=false;
        local.inRule=false;
        local.inAtKeyword=false;
        local.inSelector=false;
        local.inProperty=false;
        local.inValue=false;
        local.curStr="";
        local.arrC=[];
        for(local.i=1;local.i LTE local.length;local.i++){
            local.curChar=mid(arguments.css,local.i,1);
            local.lastChar="";
            if(local.i NEQ 1){
                local.lastChar=mid(arguments.css,local.i,1);	
            }
            local.nextChar="";
            if(local.i NEQ local.length){
                local.nextChar=mid(arguments.css,local.i+1,1);	
            }
            if(local.curChar  EQ  '/' and local.nextChar  EQ  "*"){
                // comment
                for(local.i2=local.i+2;local.i2 LTE local.length;local.i2++){
                    local.curChar2=mid(arguments.css,local.i2,1);
                    local.nextChar2="";
                    if(local.i2 LTE local.length){
                        local.nextChar2=mid(arguments.css,local.i2+1,1);
                    }
                    if(local.curChar2  EQ  '*' and local.nextChar2  EQ  "/"){
                        local.endPos=local.i2+1;
                        break;
                    }
                }
				if(local.endPos-local.i LT 1){
					local.endPos=local.length;
				}
                local.curStr=mid(arguments.css, local.i, (local.endPos-local.i)+1);
                local.t={};
                local.t.type="comment";
                local.t.value=trim(local.curStr);
                arrayappend(local.arrC, local.t);
                local.i=local.endPos;
                local.curStr="";
                
            }else if(not local.inRule){
                if(local.curChar  EQ  "}"){
                    if(local.inAtKeyword){
                        local.t={};
                        local.t.type="endatkeyword";
                        local.t.value="}";
                        local.curStr="";
                        arrayappend(local.arrC, local.t);
                    }
                }else if(local.curChar  EQ  '@'){
                    // only support import and media
                    if(mid(arguments.css,local.i+1,5)  EQ  "media"){
                        // find { and save it all as media query
                        for(local.i2=local.i+1;local.i2 LTE local.length;local.i2++){
                            local.curChar2=mid(arguments.css,local.i2,1);
                            if(local.curChar2  EQ  '{'){
                                local.endPos=local.i2;
                                break;
                            }
                        }
                        local.curStr=mid(arguments.css,local.i,local.endPos-local.i);
                        local.inAtKeyword=true;
                        local.t={};
                        local.t.type="atkeyword";
                        local.t.value=trim(local.curStr)&"{";
                        arrayappend(local.arrC, local.t);
                        local.i=local.endPos;
                        local.curStr="";
                    }else if(mid(arguments.css,local.i+1,6)  EQ  "import"){
                        // find ; or end of line and save it
                        for(local.i2=local.i+1;local.i2 LTE local.length;local.i2++){
                            local.curChar2=mid(arguments.css,local.i2,1);
                            if(local.curChar2  EQ  ';'){
                                local.endPos=local.i2;
                                break;
                            }
                        }
                        local.curStr=mid(arguments.css,local.i,local.endPos-local.i);
                        local.t={};
                        local.t.type="atkeyword";
                        local.t.value=trim(local.curStr)&";";
                        arrayappend(local.arrC, local.t);
                        local.t={};
                        local.t.type="endatkeyword";
                        local.t.value="";
                        arrayappend(local.arrC, local.t);
                        local.i=local.endPos;
                        local.curStr="";
                    }else if(mid(arguments.css,local.i+1,4)  EQ  "@z@@"){
                        local.np44=find("@", arguments.css, local.i+5);
                        if(local.np44){
                            local.curStr=mid(arguments.css, local.i+5, local.np44-(local.i+5));
                            local.t={};
                            local.t.type="fileseparator";
                            local.t.value=trim(local.curStr);
                            arrayappend(local.arrC, local.t);
                            local.curStr="";
                            local.i=(local.np44);
                            continue;
                        }
                    }else{
                        local.curStr&=local.curChar;
                    }
                }else if(local.curChar  EQ  '{'){
                    local.t={};
                    local.t.type="startselector";
                    local.t.value=trim(replace(local.curStr,chr(10)," ","all"))&"{";
                    arrayappend(local.arrC, local.t);
                    local.inRule=true;
                    local.curStr="";
                }else{
                    local.curStr&=local.curChar;
                }
            }else{
                if(local.curChar  EQ  '}'){
                    local.arrP=listtoarray(local.curStr, ";");
                    local.arrR=[];
                    for(local.i2=1;local.i2 LTE arraylen(local.arrP);local.i2++){
                        if(trim(local.arrP[local.i2]) NEQ ""){
                            local.c=listtoarray(local.arrP[local.i2],":");
                            if(arraylen(local.c)  EQ  3){
                                local.c=[local.c[1], trim(local.c[1]).trim(local.c[2])];
                            }
                            if(arraylen(local.c)  EQ  2){
                                local.t={};
                                local.t.type="property";
                                local.t.name=trim(local.c[1]);
                                local.t.value=trim(local.c[2]);
                                arrayappend(local.arrR, local.t);
                            }
                        }
                    }
                    local.t={};
                    local.t.type="rules";
                    local.t.arrProperty=local.arrR;
                    local.t.value=trim(local.curStr);
                    arrayappend(local.arrC, local.t);
                    local.inRule=false;
                    local.t={};
                    local.t.type="endselector";
                    local.t.value="}";
                    arrayappend(local.arrC, local.t);
                    local.curStr="";
                }else{
                    local.curStr&=local.curChar;
                }
            }
        }
		return local.arrC;
		</cfscript>
    </cffunction>
	
    <cffunction name="getImagesFromParsedCSS" access="private" output="yes">
    	<cfargument name="arrCSS" type="array" required="yes">
    	<cfscript>
		var local={};
		var arrImageTransparent=[];
		var arrImage=[];
		local.index=0;
		arrImageNewStylesheet=[];
		arrImageTransparentNewStylesheet=[];
		local.curLength=arraylen(arguments.arrCSS);
		//writeoutput('rel:'&variables.cssRootPath&'<br>');
		local.aliasCount=arraylen(variables.arrAlias);
		for(local.key=1;local.key LTE local.curLength;local.key++){
			local.currentCSSRootPath=variables.cssRootPath;
			local.currentCSSRootRelativePath=variables.cssRootRelativePath;
			local.curValue=arguments.arrCSS[local.key];
			if(local.curValue.type  EQ  "fileseparator"){
				local.arrTemp=listtoarray(local.curValue.value,"~");
				if(arraylen(local.arrTemp) NEQ 2){
					throw("Invalid file separator format. Must be absolutePath~relativePath","custom");
				}
				local.currentCSSRootPath=getdirectoryfrompath(local.arrTemp[1]);
				local.currentCSSRootRelativePath=getdirectoryfrompath(local.arrTemp[2]);
			}else if(local.curValue.type  EQ  "rules"){
				local.curBackgroundImage="";
				this.arr3=[];
				local.enableBackgroundSprite=false;
				for(local.i=1;local.i LTE arraylen(local.curValue.arrProperty);local.i++){
					local.c=local.curValue.arrProperty[local.i];
					if(local.c.name EQ "background-repeat" and local.c.value  EQ  "no-repeat"){ 
						local.enableBackgroundSprite=true;
					}
				}
				for(local.i=1;local.i LTE arraylen(local.curValue.arrProperty);local.i++){
					local.c=local.curValue.arrProperty[local.i];
					if(local.c.name EQ "background"){
						// parse it	into the separate values
						local.hasNoRepeat=findnocase(" no-repeat ", local.curValue.value);
						if(local.hasNoRepeat){
							local.arr2=listtoarray(local.curValue.value, " ", false);
							if(arraylen(local.arr2) EQ 5){
								local.color=local.arr2[1];
								local.url=local.arr2[2];
								local.enableBackgroundSprite=true;
                                local.t={};
                                local.t.type="property";
                                local.t.name="background-repeat";
                                local.t.value="no-repeat";
                                arrayinsertat(local.curValue.arrProperty, local.i+1, local.t);
                                local.t={};
                                local.t.type="property";
                                local.t.name="background-image";
                                local.t.value=local.url;
                                arrayinsertat(local.curValue.arrProperty, local.i+2, local.t);
								arraydeleteat(local.arr2, 1);
								arraydeleteat(local.arr2, 1);
								local.curValue.value=local.arr2[1]&" none "&arraytolist(local.arr2, " ");

							}
						}
					}else if(local.enableBackgroundSprite and local.c.name EQ "background-image"){
						local.curBackgroundImage=trim(replace(replace(replace(replace(local.c.value, "'", "", "all"), '"', '', "all"), 'url(','', "all"), ')','', "all"));
					}else{
						arrayappend(this.arr3, local.c);
					}
				}
				if(local.curBackgroundImage NEQ ""){
					local.curBackgroundImage=this.forceAbsoluteDir(local.curBackgroundImage, local.currentCSSRootPath, this.root);
					if(mid(local.curBackgroundImage, 1, len(this.root)) NEQ this.root){
						local.curBackgroundImage="";	
					}else{
						local.curBackgroundImage=removechars(local.curBackgroundImage, 1, len(this.root)-1);
						for(local.n=1;local.n LTE local.aliasCount;local.n++){
							local.currentCSSRootRelativePath=variables.arrAlias[local.n];
							local.currentCSSRootPath=this.aliasStruct[variables.arrAlias[local.n]];
							if(mid(local.curBackgroundImage, 1,len(local.currentCSSRootRelativePath)) EQ local.currentCSSRootRelativePath){
								break;
							}
						}
						local.curBackgroundImage=this.forceAbsoluteDir(mid(local.curBackgroundImage, len(local.currentCSSRootRelativePath), len(local.curBackgroundImage)-(len(local.currentCSSRootRelativePath)-1)) , local.currentCSSRootPath, local.currentCSSRootPath);
						if(mid(local.curBackgroundImage, 1, len(local.currentCSSRootPath)) NEQ local.currentCSSRootPath){
							local.curBackgroundImage="";	
						}
					}
					if(local.curBackgroundImage NEQ ""){
						local.c={};
						local.c.type="property";
						local.c.name="background-image";
						local.arrTemp=listtoarray(local.curBackgroundImage, "?");
						local.curBackgroundImage=local.arrTemp[1];
						local.ext=mid(local.curBackgroundImage, len(local.curBackgroundImage)-3,4);
						if(arraylen(local.arrTemp) GTE 2){
							local.curBackgroundImage&="?"&local.arrTemp[2];
						}
						if(local.ext  EQ  ".jpg"){
							local.c.imageIndex=arraylen(arrImage)+1;
							local.c.transparentIndex=-1;
							arrayappend(arrImage, local.curBackgroundImage);
						}else if(local.ext  EQ  ".png"  OR  local.ext  EQ  ".gif"){
							local.c.imageIndex=-1;
							local.c.transparentIndex=arraylen(arrImageTransparent)+1;
							arrayappend(arrImageTransparent, local.curBackgroundImage);
						}
						local.c.value="url("&local.curBackgroundImage&")";
						arrayappend(this.arr3, local.c);
					}
				}
				local.curValue.arrProperty=this.arr3;
			}
		}
		return {arrImage:arrImage, arrImageTransparent: arrImageTransparent};
		</cfscript>
    </cffunction>
    
    
    <cffunction name="generateSpriteMaps" access="private" output="no">
    	<cfargument name="imageStruct" type="struct" required="yes">
    	<cfscript>
		var local={};
		var arrImage=arguments.imageStruct.arrImage;
		var arrImageTransparent=arguments.imageStruct.arrImageTransparent;
		local.imageStructNew=[];
		local.imageTransparentStructNew=[];
		local.arrLookupImage=[];
		local.arrLookupTransparent=[];
		if(this.disableSpritemap EQ 0){
			local.spriteMapJpegFileNameV=this.jpegFilePath&"?zv="&randrange(1034212,92301493);
			local.spriteMapPngFileNameV=this.pngFilePath&"?zv="&randrange(1034212,92301493);
			if(arraylen(arrImage) NEQ 0){
				local.imageStructNew=this.generateSpriteMap(arrImage, this.jpegFilePath);
				
				for(local.i in local.imageStructNew){
					local.arrLookupImage[local.imageStructNew[local.i].curIndex]=local.i;
				}
			}
			if(arraylen(arrImageTransparent) NEQ 0){
				local.imageTransparentStructNew=this.generateSpriteMap(arrImageTransparent, this.pngFilePath);
				for(local.i in local.imageTransparentStructNew){
					local.arrLookupTransparent[local.imageTransparentStructNew[local.i].curIndex]=local.i;
				}
			}
		}
		return { imageStruct:local.imageStructNew, imageTransparentStruct:local.imageTransparentStructNew, arrLookupImage:local.arrLookupImage, arrLookupTransparent:local.arrLookupTransparent};
		</cfscript>
    </cffunction>
    
    <cffunction name="rebuildCSS" access="private" output="no">
    	<cfargument name="arrCSS" type="array" required="yes">
    	<cfargument name="imageStruct" type="struct" required="yes">
    	<cfscript>
		var local={};
		local.a=[];
		local.lastVal="";
		local.originalStruct=duplicate(arguments.imageStruct);
		for(local.key=1;local.key LTE arraylen(arguments.arrCSS);local.key++){
			local.curValue=arguments.arrCSS[local.key];
			if(local.curValue.type  EQ  "fileseparator"){
				continue;
			}else if(local.curValue.type  EQ  "rules"){
				for(local.i=1;local.i LTE arraylen(local.curValue.arrProperty);local.i++){
					local.c=local.curValue.arrProperty[local.i];
					if(local.c.name  EQ  "background-image"){
						local.match=false;
						if(this.disableSpritemap EQ 0){
							if(structkeyexists(local.c, 'imageIndex') and local.c.imageIndex GT 0){
								local.match=true;
								local.f=arguments.imageStruct.imageStruct[arguments.imageStruct.arrLookupImage[local.c.imageIndex]];
								local.f.selector=local.lastVal;
								if(structkeyexists(local.f, 'referenceIndex')){
									local.t=local.originalStruct.imageStruct[local.f.referenceIndex];
									local.f.left=local.t.left;
									local.f.top=local.t.top;
									local.f.width=local.t.width;
									local.f.height=local.t.height;
									
								}
								if(local.f.width  EQ  0) continue;
								local.curValue.arrProperty[local.i].value="url("&this.jpegRootRelativePath&")";
								if(local.f.left NEQ 0){
									local.f.left*=-1;
								}
								if(local.f.top NEQ 0){
									local.f.top*=-1;
								}
								if(this.disableMinify){
									arrayappend(local.a, chr(9));
								}
								arrayappend(local.a, "background-position:"&(local.f.left-this.spritePad)&"px "&(local.f.top-this.spritePad)&"px;");
								if(this.disableMinify){
									arrayappend(local.a, chr(10));
								}
							}
							if(structkeyexists(local.c, 'transparentIndex') and local.c.transparentIndex GT 0){
								local.match=true;
								local.f=arguments.imageStruct.imageTransparentStruct[arguments.imageStruct.arrLookupTransparent[local.c.transparentIndex]];
								local.f.selector=local.lastVal;
								if(structkeyexists(local.f, 'referenceIndex')){
									local.t=local.originalStruct.imageTransparentStruct[local.f.referenceIndex];
									local.f.left=local.t.left;
									local.f.top=local.t.top;
									local.f.width=local.t.width;
									local.f.height=local.t.height;
									
								}
								if(local.f.width  EQ  0) continue;
								local.curValue.arrProperty[local.i].value="url("&this.pngRootRelativePath&")";
								if(local.f.left NEQ 0){
									local.f.left*=-1;
								}
								if(local.f.top NEQ 0){
									local.f.top*=-1;
								}
								if(this.disableMinify){
									arrayappend(local.a, chr(9));
								}
								arrayappend(local.a, "background-position:"&(local.f.left-this.spritePad)&"px "&(local.f.top-this.spritePad)&"px;");
								if(this.disableMinify){
									arrayappend(local.a, chr(10));
								}
							}
							if(not local.match){
								local.curValue.arrProperty[local.i].value=replace(replace(local.curValue.arrProperty[local.i].value, '"', '', "all"), ")","?zv="&randrange(1034212,92301493)&")", "all");
							}
						}
					}
					if(this.disableMinify){
						arrayappend(local.a, chr(9));
					}
					arrayappend(local.a, local.curValue.arrProperty[local.i].name&":"&local.curValue.arrProperty[local.i].value&";");	
					if(this.disableMinify){
						arrayappend(local.a, chr(10));
					}
				}
			}else{
				local.lastVal=local.curValue.value;
				if(this.disableMinify){
					if(not find(","&local.curValue.type&",", ",endatkeyword,atkeyword,endselector,startselector,comment,")){
						arrayappend(local.a, chr(9));
					}
				}else{
					if(local.curValue.type EQ "startselector"){
						arrayappend(local.a, replace(local.curValue.value, chr(10)," ","all"));
					}else if(local.curValue.type NEQ "comment"){
						arrayappend(local.a, local.curValue.value);
					}
				}
				if(this.disableMinify){
					arrayappend(local.a, chr(10));
				}
			}
		}
		// fix @font-face
		local.s=replace(replace(replace(arraytolist(local.a,""), "font-face", "@font-face", "all"), "@@font-face","@font-face", "all"), this.root, "/", "all");
		return local.s;
		</cfscript>
    </cffunction>
    
    
    
    

    </cfoutput>
</cfcomponent>