<cfcomponent>
	<cffunction name="index" access="remote">
    	<cfsetting requesttimeout="5">
    	<cfscript>
		var local={};
		local.startTime=getTickCount();
		local.relativePath=getdirectoryfrompath(cgi.SCRIPT_NAME);
		local.root=getdirectoryfrompath(getcurrenttemplatepath());
		local.root=mid(local.root, 1, len(local.root)-(len(local.relativePath)-1));
		local.exampleDirAbs=expandpath(getdirectoryfrompath(cgi.SCRIPT_NAME)&"example/");
		
		local.cssSpriteMap=createobject("component", "cssSpriteMap");
		local.cssSpriteMap.init({
			root:local.root, 
			charset:"utf-8",
			spritePad:1,
			aliasStruct:{
				"/":local.root,
				"/cssSpriteMapAlias/":local.exampleDirAbs&"alias/"
			},
			jpegFilePath:local.exampleDirAbs&"cssSpriteMap.jpg",
			pngFilePath:local.exampleDirAbs&"cssSpriteMap.png",
			jpegRootRelativePath:local.relativePath&"example/cssSpriteMap.jpg",
			pngRootRelativePath:local.relativePath&"example/cssSpriteMap.png",
			disableSpriteMap:false,
			root:local.root
		
		});
		local.css=local.cssSpriteMap.loadCSSFile(local.exampleDirAbs&"example.css", local.relativePath&"example/example.css");
		
		/*
		// load an array of css files
		local.css=local.cssSpriteMap.loadCSSFileArray([
			{absolutePath:local.exampleDirAbs&"example.css",relativePath:local.relativePath&"example/example.css"}
		]);*/
		
		/*
		// load css from a string
		local.css=".sh-1{background-image:url(../example/jetendo-cms-logo.jpg); background-repeat:no-repeat;}";
		*/

		local.cssSpriteMap.setCSSRoot(local.exampleDirAbs, local.relativePath&"example/");
		//local.cssSpriteMap.aliasStruct={};
		//this.setCSSRoot("/home/vhosts/jetendo_com/public_html/stylesheets/", "/stylesheets/");
		local.rs=local.cssSpriteMap.convertAndReturnCSS(local.css);
		local.cssSpriteMap.saveCSS(local.exampleDirAbs&"cssSpriteMap.css", local.rs.css);
		local.cssSpriteMap.displayCSS(local.rs.arrCSS, local.rs.cssStruct);
		writeoutput(((gettickcount()-local.startTime)/1000)&' seconds<br>');
		
		abort;
		</cfscript>
	</cffunction>
</cfcomponent>