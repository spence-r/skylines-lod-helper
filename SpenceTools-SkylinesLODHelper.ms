-- 	Cities:Skylines LOD baker
--	By Spence - spence@commonspence.com
-- 	ver. 4 Jan 2019
--
--	https://gumroad.com/l/skylinesLODhelper
--	https://gumroad.com/commonspence
--	*********************************************************************
--
--	What this script does:	
--		Speeds up the process for baking LODs (especially for multiple LOD assets sharing the same texture set) 
--		All separate texture maps (diffuse, specular, normal, illumination, color, alpha) are baked in one click
--		Automatically sets up the LOD for a projection bake (assigns some bake settings and a Projection modifier) if you didn't do this already
--		Automatically disables the ray miss check and sets bake size and padding/dilation from the controls in the script. Other bake options can be changed in Max render-to-texture dialog
--
--	What it installs:
--		SpenceTools-SkylinesLODHelper.mcr to %LocalAppData%/Autodesk/3dsMax/...(your max version).../ENU/usermacros
--
--	How to use it:
--		Install and add to your Max UI like any other macroscript (find it in category SpenceTools)
--		Set up the output path and adjust padding, bake size, cage push amount if desired.
--		Use the buttons to select your mesh/LOD mesh from the scene. The names should match the format expected by Cities:Skylines importer [meshName, meshName_lod] and must be different from each other.
--		Select an input map for each channel with the ... buttons. 
--		Uncheck any maps you don't need to bake (alpha, color etc)
-- 		When you are ready to bake press Bake Maps.
--		Maps are saved to the output location you specified, in the format:
--						ObjectName_MapType (object Box001, diffuse map = Box001_d)
--	
--		The script attempts to detect some common errors and will alert you with a message in the log area (above the bake button)
--
--	Known issues: 
--		Auto cage push option isn't always applied when making a new Projection modifier. If you get a bad bake just push the cage manually, then bake again. 
--
--
--		If you find problems or have questions, please email me.
--		However, I can't guarantee to provide any support. 
--		Use this script at your own risk!
--
--	*********************************************************************
--

macroScript SkylinesLODHelper category: "SpenceTools"
(
	rollout SkylinesLODBakerRollout "Skylines LOD Helper" width:288 height:570
	( 
		-- is it possible to bake maps for each of these types?
		-- this means that they are enabled and a valid map is specified.
		local canBakeDiffuse	= false
		local canBakeSpec		= false
		local canBakeNormal		= false
		local canBakeColor		= false
		local canBakeIllum		= false
		local canBakeAlpha		= false
		
		-- invalid or unspecified file paths
		local pathsWithInvalidFile = "" ; local pathsWithNoFile = ""
		
		-- LOD and Mesh objects
		local lodObject; local meshObject
		
		-- folder path to where the baked files are saved
		local outputPath
		
		label hdrtext "Skylines LOD Helper"
		label hdrlink "By Spence"
		label hdrlink2 "spence@commonspence.com"
		
		editText 'MeshNameText' "" pos:[120,72] width:160 height:16 readonly:true align:#left
		editText 'LODNameText' "" pos:[120,104] width:160 height:16 readonly:true align:#left
				
		fn MeshPickFilter obj = 
			return obj.name != LODNameText.text
			
		fn LODPickFilter obj =
			return obj.name != MeshNameText.text
		
		pickButton 'PickMeshButton' "Pick Mesh" pos:[16,72] width:96 height:24 align:#left tooltip:"Selects the mesh you want to bake LOD from.\r\nMust have a different name than the LOD." filter:MeshPickFilter
		pickButton 'PickLODButton' "Pick LOD Mesh" pos:[16,104] width:96 height:24 align:#left tooltip:"Selects the LOD mesh to bake to.\r\nMust have a different name than the high detail mesh." filter:LODPickFilter
		
		button 'ClearMeshButton' "Clear Meshes" pos:[150,122] width:120 height:16 align:#left tooltip:"Clear the mesh references."
		
		groupBox 'MapsGroup' "Maps" pos:[8,136] width:272 height:148 align:#left
		
			checkbox 'DiffuseCheck' "Diffuse" pos:[16,176] width:50 height:16 align:#left checked:true tooltip:"Bake LOD Diffuse map."
			checkbox 'SpecCheck' "Spec" pos:[16,192] width:50 height:16 align:#left checked:true tooltip:"Bake LOD Specular map."
			checkbox 'NormalCheck' "Normal" pos:[16,208] width:50 height:16 align:#left checked:true tooltip:"Bake LOD Normal map."
			checkbox 'ColorCheck' "Color" pos:[16,224] width:50 height:16 align:#left checked:true tooltip:"Bake LOD Color map."
			checkbox 'IllumCheck' "Illum" pos:[16,240] width:50 height:16 align:#left checked:true tooltip:"Bake LOD Illumination map."
			checkbox 'AlphaCheck' "Alpha" pos:[16,256] width:50 height:16 align:#left checked:true tooltip:"Bake LOD Alpha map."
			
			button 'ClearDiffusePathButton' "X" pos:[78,176] width:18 height:16
			button 'DiffusePathButton' "..." pos:[96,176] width:18 height:16
			editText 'DiffusePathText' "" pos:[112,176] width:160 height:16 readOnly:false align:#left 
		
			button 'ClearSpecPathButton' "X" pos:[78,192] width:18 height:16		
			button 'SpecPathButton' "..." pos:[96,192] width:18 height:16
			editText 'SpecPathText' "" pos:[112,192] width:160 height:16 readOnly:false align:#left 

			button 'ClearNormalPathButton' "X" pos:[78,208] width:18 height:16					
			button 'NormalPathButton' "..." pos:[96,208] width:18 height:16			
			editText 'NormalPathText' "" pos:[112,208] width:160 height:16 readOnly:false align:#left 
		
			button 'ClearColorPathButton' "X" pos:[78,224] width:18 height:16				
			button 'ColorPathButton' "..." pos:[96,224] width:18 height:16			
			editText 'ColorPathText' "" pos:[112,224] width:160 height:16 readOnly:false align:#left
			
			button 'ClearIllumPathButton' "X" pos:[78,240] width:18 height:16					
			button 'IllumPathButton' "..." pos:[96,240] width:18 height:16			
			editText 'IllumPathText' "" pos:[112,240] width:160 height:16 readOnly:false align:#left

			button 'ClearAlphaPathButton' "X" pos:[78,256] width:18 height:16					
			button 'AlphaPathButton' "..." pos:[96,256] width:18 height:16			
			editText 'AlphaPathText' "" pos:[112,256] width:160 height:16 readOnly:false align:#left
			
			button 'SelectAllButton' "All" pos:[16,160] width:40 height:16 align:#left tooltip:"Select all maps."
			button 'SelectNoneButton' "None" pos:[56,160] width:40 height:16 align:#left tooltip:"Select no maps."
			button 'ClearMapsButton' "Clear All Paths" pos:[150,160] width:120 height:16 align:#left tooltip:"Clear all map paths."
			-- end MapsGroup
				
		groupBox 'BakeSettingsGroup' "Bake Settings" pos:[8,292] width:272 height:80 align:#left
		
			spinner 'MapXSz' "Width " pos:[20,310] range:[16,8192,128] type:#integer fieldwidth:40 align:#left
			spinner 'MapYSz' "Height" pos:[20,330] range:[16,8192,128] type:#integer fieldwidth:40 align:#left
			checkbutton MapSizeLock "" pos:[105,320] checked:true iconName:"Common/Lock" iconSize:[16,16] align:#left width:16 height:16 tooltip:"Lock height to width"			
			
			spinner 'PaddingAmount' "Padding" pos:[130,310] range:[0,64,16] type:#integer fieldwidth:24
			spinner 'AutoCagePush'	"Auto Cage Push" pos:[130,330] range:[0,5,0.1] type:#float fieldwidth:55  tooltip:"Automatically pushes cage by this amount when adding a projection modifier to the LOD mesh."
		
			button 'OpenRTT' "RTT Opts." pos:[210, 305] tooltip:"Opens the Max render-to-texture dialog."
		
			label 'OutputPathLabel' "Output Path" pos:[20,350]
			button 'OutputPathButton' "..." pos:[96,350] width:18 height:16
			editText 'OutputPathText' "" pos:[112,350] width:160 height:16 readOnly:false align:#left
			-- end BakeSettingsGroup
		
		editText 'MessageText' "" pos:[8,382] width:272 height:120 readOnly:true
		button 'BakeMapsButton' "Bake Maps" pos:[8,514] width:272 height:52 tooltip:"Bake all selected maps."
		button 'OpenOutputDirectory' "Open Output Folder" pos:[8,578] width:272 height:24
				
		-- open a file select dialog for a map image
		--
		-- type: type string used for the dialog title. 
		fn PickFilePath type = 
		(
			capt = append "Pick " type ; append capt " Map File:"
			return getOpenFileName caption:capt filename:(maxfilepath) types:"PNG (*.png)|*.png|JPG (*.jpg)|*.jpg|JPEG (*.jpeg)|*.jpeg|TGA (*.tga)|*.tga|BMP (*.bmp)|*.bmp|All|*.*|"
		)
		
		-- check an (enabled) map's file path. 
		-- if the path isn't specified or it's invalid, alert the user.
		-- otherwise, flag the specified map type as bakeable.
		--
		-- enabled: check specifying whether path is enabled
		-- path: file path string
		-- type: type string for the output feed, eg 'diffuse' or 'alpha'
		-- canBakeMap: reference to flag for 
		-- 		this map type (canBakeDiffuse, canBakeAlpha)
		fn CheckPath enabled path type &canBakeMap = 
		(
			canBakeMap = false
			if enabled then
			(			
				if path == "" then (
					append pathsWithNoFile type
					return false )
				else if not doesFileExist(path) then (
					append pathsWithInvalidFile type
					return false )
				else ( 
					canBakeMap = true
					return true )
			) 
		)
		
		-- check paths for every map type. 
		-- will alert user if paths are bad or nonexistent.
		-- otherwise, baking will be permitted for any selected maps.
		fn CheckAllPaths =
		(
			pathsWithNoFile = ""
			pathsWithInvalidFile = ""
			
			CheckPath DiffuseCheck.checked DiffusePathText.text "Diffuse " &canBakeDiffuse
			CheckPath SpecCheck.checked SpecPathText.text "Spec " &canBakeSpec
			CheckPath NormalCheck.checked NormalPathText.text "Normal " &canBakeNormal
			CheckPath ColorCheck.checked ColorPathText.text "Color " &canBakeColor
			CheckPath IllumCheck.checked IllumPathText.text "Illum " &canBakeIllum
			CheckPath AlphaCheck.checked AlphaPathText.text "Alpha" &canBakeAlpha
		)
				
		-- render a map for the LOD object.
		--	
		-- bProps: bake properties interface
		-- bmpPath: file path pointing to a texture map to be transferred to the LOD.
		-- suffix: type suffix for creating the filename based on the map type, eg "_d" "_n" "_i"
		-- type: type string for logging, eg "Diffuse" "Normal" "Illumination"
		fn BakeMap bProps bmpPath suffix type =
		(		
			-- make material and assign bmp at bmpPath to its diffuse channel
			bakeMat = StandardMaterial()
			meshObject.material = bakeMat
			showTextureMap meshObject.material on
		
			bmp = openBitMap bmpPath
			bmpTex = BitmapTexture()
			bmpTex.bitmap = bmp
			
			bakeMat.diffuseMap = bmpTex

			-- now, bake the map.		
			-- clear any preexisting bake elements
			bProps.removeAllBakeElements()
			
			-- create the bake element and initialize its properties
			bakeElem = DiffuseMap()
			bakeElem.enabled = true
			bakeElem.outputSzX = MapXSz.value
			bakeElem.outputSzY = MapYSz.value
			bakeElem.filenameUnique = false
			bakeElem.elementName = "LODBakedMap"
			
			bakeElem.fileType = (getFilenamePath OutputPathText.text + LODObject.name + suffix + ".png")
			bakeElem.fileName = filenameFromPath bakeElem.fileType  
			
			-- add the bake element we just made
			bProps.addBakeElement bakeElem
			
			-- select LOD object, then bake maps from selection.
			select lodObject
			render rendertype:#bakeSelected vfb:off progressBar:true outputSize:[MapXSz.value,MapYSz.value]
		
			-- finished baking, return a string we can log.
			return "Baked " + type + " Map.\r\n"
		)
		
		-- bake all enabled maps.
		-- checks each map slot to see whether it's enabled.
		-- then, applies the specified texture in diffuse channel before baking out a map.
		-- other channels are unnecessary because we just want to transfer maps between mesh/LOD.
		fn BakeAllMaps = 
		(
			local bakeMsg = ""
			local prevMat = meshObject.material
			
			local bakeProps = lodObject.INodeBakeProperties
			local projBakeProps = lodObject.INodeBakeProjProperties
			
			-- initialize bake properties
			bakeProps.bakeEnabled = true
			bakeProps.bakeChannel = 1
			bakeProps.nDilations = PaddingAmount.value
				
			-- now set up the projection modifier.
			local projMod = undefined
			local noMod = true

				-- look for an existing projection modifier on the LOD:
				-- 		if one is found it will be used as the projection modifier for baking. we don't care about more than 1 projection modifier!
				-- 		if not, create one and initialize its properties. 	
				for mod in lodObject.modifiers while noMod where (classof mod == projection) 
					do (
						projMod = mod 
						noMod = false ) 
					if noMod do (
							projMod = projection()
							addmodifier lodObject projMod 
							
							-- set up the added projection modifier
							projMod.addObjectNode(meshObject)
							projMod.resetCage()
							projMod.pushCage(AutoCagePush.value)
							
							projMod.displayCage = true )
			
			-- now set projection bake settings.
			projBakeProps.enabled = true
			
			projBakeProps.projectionMod = projMod
			projBakeProps.warnRayMiss = false
			

			-- now bake
			if (canBakeDiffuse) 
			then append bakeMsg (BakeMap bakeProps DiffusePathText.text "_d" "Diffuse")
			
			if (canBakeSpec)
			then append bakeMsg (BakeMap bakeProps SpecPathText.text "_s" "Specular")
			
			if (canBakeNormal)
			then append bakeMsg (BakeMap bakeProps NormalPathText.text "_n" "Normal")
			
			if (canBakeColor)
			then append bakeMsg (BakeMap bakeProps ColorPathText.text "_c" "Color")
			
			if (canBakeIllum) 
			then append bakeMsg (BakeMap bakeProps IllumPathText.text "_i" "Illumination")
				
			if canBakeAlpha
			then append bakeMsg (BakeMap AlphaPathText.text "_a" "Alpha")
			
			meshObject.material = prevMat
			return bakeMsg
		)	
		
		-- bake all maps button
		on BakeMapsButton pressed do
		(		
			-- system sound class for playing dings
			sysSnd = dotNetClass "System.Media.SystemSounds"
			
			-- the messages to display for errors output.
			errorMsg = ""
			
			-- set and validate mesh and LOD objects
			meshObject = getNodeByName MeshNameText.text
			if (meshObject == undefined) 
			then append errorMsg "   No mesh selected.\r\n" 
			
			lodObject = getNodeByName LODNameText.text
			if (lodObject == undefined) 
			then append errorMsg "   No LOD mesh selected.\r\n" 

			if (meshObject == lodObject and 
				(meshObject != undefined or lodObject != undefined) ) 
			then append errorMsg "   Mesh and LOD are the same - repick meshes.\r\n" 
			
			-- make sure at least one map is selected
			if	not DiffuseCheck.checked and 
				not SpecCheck.checked and 
				not NormalCheck.checked	and 
				not ColorCheck.checked and 
				not IllumCheck.checked and 
				not AlphaCheck.checked 
			then append errorMsg "   No maps selected for baking.\r\n"
			
			-- check all paths for validity; enable map baking on valid paths
			CheckAllPaths()
			
			-- these maps have no file specified
			if pathsWithNoFile != "" 
			then append errorMsg ("   These maps are enabled but have no file path:\r\n\t" +
				pathsWithNoFile + "\r\n")
				
			-- these maps have invalid path specified
			if pathsWithInvalidFile != "" 
			then append errorMsg ("   These maps are enabled but file is invalid:\r\n\t" +
				pathsWithInvalidFile + "\r\n")
				
			if OutputPathText.text == ""
			then append errorMsg "   No output path set.\r\n"
			
			-- log error messages if there were any, and alert user.
			-- otherwise, do a bake and log which maps were baked.
			if (errorMsg != "") then (
				MessageText.text = append "Errors:\r\n" errorMsg
				sysSnd.Beep.Play() 
			) else (
				MessageText.text = ""
				bake = BakeAllMaps()
				
				-- should always get something back in the bake string. 
				-- if not, something went wrong - we shouldn't have been able to bake at all
				if bake != ""
				then MessageText.text = bake 
				else MessageText.text = "No maps baked." 
			)
		)
		
		-- select mesh button
		on PickMeshButton picked obj do 
			MeshNameText.text = obj.name
		
		-- select LOD button
		on PickLODButton picked obj do
			LODNameText.text = obj.name
		
		-- clear meshes button
		on ClearMeshButton pressed do
		(
			LODNameText.text = ""
			MeshNameText.text = ""
			lodObject = undefined
			meshObject = undefined
		)
		
		-- enable all maps
		on SelectAllButton pressed do 
		(
			DiffuseCheck.checked = true
			SpecCheck.checked = true
			NormalCheck.checked = true
			ColorCheck.checked = true
			IllumCheck.checked = true
			AlphaCheck.checked = true
		)
		
		-- disable all maps
		on SelectNoneButton pressed do
		(
			DiffuseCheck.checked = false
			SpecCheck.checked = false
			NormalCheck.checked = false
			ColorCheck.checked = false
			IllumCheck.checked = false
			AlphaCheck.checked = false
		)
		
		-- clear map paths
		on ClearMapsButton pressed do
		(
			DiffusePathText.text = ""
			SpecPathText.text = ""
			NormalPathText.text = ""
			ColorPathText.text = ""
			IllumPathText.text = ""
			AlphaPathText.text = ""
		)
		
		-- pick/clear diffuse
		on DiffusePathButton pressed do 
		(
			diffusePath = PickFilePath "Diffuse" 
			if diffusePath != undefined 
			then DiffusePathText.text = diffusePath
		)
	
		on ClearDiffusePathButton pressed do
			DiffusePathText.text = ""
		
		-- pick/clear spec
		on SpecPathButton pressed do 
		(
			specPath = PickFilePath "Specular" 
			if specPath != undefined 
			then SpecPathText.text = specPath
		)
		
		on ClearSpecPathButton pressed do
			SpecPathText.text = ""	
		
		-- pick/clear normal
		on NormalPathButton pressed do 
		(
			normalPath = PickFilePath "Normal" 
			if normalPath != undefined
			then NormalPathText.text = normalPath
		)
		
		on ClearNormalPathButton pressed do
			NormalPathText.text = ""	

		-- pick/clear color
		on ColorPathButton pressed do 
		(
			colorPath = PickFilePath "Color" 
			if colorPath != undefined 
			then ColorPathText.text = colorPath
		)
		
		on ClearColorPathButton pressed do
			ColorPathText.text = ""		

		-- pick/clear illumination
		on IllumPathButton pressed do 
		(
			illumPath = PickFilePath "Illumination" 
			if illumPath != undefined 
			then IllumPathText.text = illumPath
		)

		on ClearIllumPathButton pressed do
			IllumPathText.text = ""
		
		-- pick/clear alpha
		on AlphaPathButton pressed do 
		(
			alphaPath = PickFilePath "Alpha" 
			if alphaPath != undefined
			then AlphaPathText.text = alphaPath
		)
		
		on ClearAlphaPathButton pressed do
			AlphaPathText.text = ""
		
		-- bake settings
		on MapXSz changed newX do
		(
			local xSz = newX
			local modX = mod newX 16
			
			if modX != 0 do
				MapXSz.value = newX - modX 
				
			if MapSizeLock.checked do 
				MapYSz.value = MapXSz.value		
		)
		
		on MapYSz changed newY do
		(
			local ySz = newY
			local modY = mod newY 16
			
			if modY != 0 do
				MapYSz.value = newY - modY 
				
			if MapSizeLock.checked do 
				MapXSz.value = MapYSz.value	
		)
		
		on MapSizeLock changed locked do
			if locked do
				MapYSz.value = MapXSz.value
				
		on OpenRTT pressed do
		(
			macros.run "Render" "BakeDialog"
		)	
				
		-- output path selection button
		on OutputPathButton pressed do
		(
			outputPath = getSavePath filename:(maxfilepath)
			if outputPath != undefined then OutputPathText.text = append outputPath "\\"
		)
		
		-- explore to output path
		on OpenOutputDirectory pressed do
		(
			if outputPath != undefined do 
				shellLaunch "explorer.exe" outputPath
		)
		
		-- allow pasting/typing in an output path.
		-- note - should really validate path for trailing \
		on OutputPathText changed newPath do 
		(
			outputPath = newPath
		)

	) -- end rollout
	
	createDialog SkylinesLODBakerRollout 288 612
)