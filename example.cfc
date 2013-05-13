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
			charset:"utf-8", // the charset used to read and write CSS files
			spritePad:1, // the number of pixels between each image in the sprite image. At least 1 pixel is recommended for best browser rendering compatibility.
			disableMinify: false, // Set disableMinify to true to output CSS with perfect indenting and line breaks
			aliasStruct:{
				"/":local.root,
				// if you normal server files from a web server alias directory like this in nginx:
				// location /cssSpriteMapAlias { alias /path/to/cssSpriteMap-dot-cfc/example/alias; }
				// cssSpriteMap-dot-cfc can process the alias folder if you specify any additional folders to use when evaluating the absolute path of a file.
				// This even works when the web server alias doesn't exist, so we have a fake alias setup in the example by default
				"/cssSpriteMapAlias/":local.exampleDirAbs&"alias/"
			},
			jpegFilePath:local.exampleDirAbs&"cssSpriteMap.jpg", // the absolute path to the JPEG sprite image that will be output
			pngFilePath:local.exampleDirAbs&"cssSpriteMap.png", // the absolute path to the PNG sprite image that will be output. i.e. /absolute/path/to/cssSpriteMap.jpg
			jpegRootRelativePath:local.relativePath&"example/cssSpriteMap.jpg", // the root relative path to the JPEG sprite image that will be output. i.e. /path/to/cssSpriteMap.jpg
			pngRootRelativePath:local.relativePath&"example/cssSpriteMap.png", // the root relative path to the PNG sprite image that will be output. i.e. /path/to/cssSpriteMap.jpg
			disableSpriteMap:false, // disable the sprite map feature and only concatenate and minify the CSS
			root:local.root // specify the root directory for the current web server virtual host
		
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