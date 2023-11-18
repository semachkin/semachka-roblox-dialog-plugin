local CoreGui = game:GetService'CoreGui'

local classes = script.Parent
local fieldClasses = classes.field
local collectorClasses = classes.collectors

local window: window.constructor = require(classes.window)
local coreGui: coreGui.constructor = require(classes.coreGui)
local dialog: dialog.constructor = require(fieldClasses.dialog)
local speech: speech.constructor = require(fieldClasses.dialog.speech)
local answer: answer.constructor = require(fieldClasses.dialog.speech.answer)
local marker: marker.constructor = require(fieldClasses.marker)
local decryptor: decryptor.constructor = require(collectorClasses.localDecryptor)

type void = nil

type toolbar = {
	-- properties
	
	instance: PluginToolbar,
	plugin: Plugin,
	
	dialogEditor: window.object,
	
	coreGuiFolder: Folder,
	newDialogGui: coreGui.object,
	importDialogGui: coreGui.object,
	
	-- methods
	
	importDialog: (
		deserialized: dialog.serializeVersion, 
		container: BinaryStringValue
	) -> dialog.object
}
type toolbarConstructor = (
	plugin: Plugin,
	name: string
) -> toolbar

export type object = toolbar
export type constructor = toolbarConstructor

if shared.toolbarConstructor then 
	return shared.toolbarConstructor :: toolbarConstructor
end

local toolbar: pluginWindowConstructor = function(plugin, name)
	local new: toolbar = {}
	
	do
		local lastFolder = CoreGui:FindFirstChild(name)
		if lastFolder then
			lastFolder:Destroy()
		end
	end
	
	local pluginToolbar: PluginToolbar = plugin:CreateToolbar(name)
	local coreGuiFolder: Folder = Instance.new'Folder'
	
	coreGuiFolder.Parent = CoreGui
	coreGuiFolder.Name = name

	new.instance = pluginToolbar
	new.plugin = plugin
	new.coreGuiFolder = coreGuiFolder
	
	local dialogEditor: window.object
	local newDialogGui: coreGui.object
	local importDialogGui: coreGui.object
	
	do
		local dialogEditorIcon = 'rbxassetid://15127213611'
		local dialogEditorSize = Vector2.new(500, 500)
		
		dialogEditor = --[[new]] window(
			new, 
			true,
			'dialog editor', 
			dialogEditorSize, 
			dialogEditorIcon
		)
		
		newDialogGui = --[[new]] coreGui(new, 'new dialog')
		importDialogGui = --[[new]] coreGui(new, 'import dialog')
	end
	
	function new.importDialog(deserialized, container)
		local dialogEditorBackground = dialogEditor.instance.dialogEditorBackground
		local grid = dialogEditorBackground.field.grid	
		
		local initMarker = shared.initMarker
		
		local MARKER_INIT_MODE_SPEECH = shared.MARKER_INIT_MODE_SPEECH
		local MARKER_INIT_MODE_ENTER  = shared.MARKER_INIT_MODE_ENTER
		local MARKER_INIT_MODE_ANSWER = shared.MARKER_INIT_MODE_ANSWER
		
		-- init markers --
		shared.clearGrid()
		
		local markersDecryptor: decryptor.object = shared.markersDecryptor
		
		local function importMarker(serialized: marker.serializeVersion, hash)
			local newMarker: marker.object = --[[new]] marker(
				serialized.maxOutputs, 
				true, 
				grid, 
				serialized.name, 
				serialized.color, 
				serialized.position, 
				serialized.size, 
				serialized.outputs, 
				serialized.nHaveInput,
				serialized.locked, 
				hash
			)
			
			if serialized.name == 'Entry' then -- TODO: enter init
				initMarker(MARKER_INIT_MODE_ENTER, newMarker)
			end

			deserialized.markers[hash] = newMarker
		end
		
		local stack = {}
		
		local function checkImportedMarker(marker: marker.serializeVersion, hash)
			local outputs = marker.outputs
			
			for _,ancestorHash in next, outputs do
				local ancestor: marker.object = markersDecryptor.fire(ancestorHash)
				if not ancestor then 
					stack[hash] = marker
					return
				end
			end
			
			importMarker(marker, hash)
			stack[hash] = nil
		end
		
		for i,v in next, deserialized.markers do
			checkImportedMarker(v, i)
		end
		while next(stack) do
			for i, v in next, stack do
				checkImportedMarker(v, i)
			end
			task.wait()
		end
		
		-- init speechs --
		for i,v: speech.object in next, deserialized.speechs do
			local marker: marker.object = deserialized.markers[v.marker]
			
			local newSpeech: speech.object = --[[new]] speech(
				marker, 
				v.words, 
				i, 
				v.answers
			)
			
			marker.parentHash = newSpeech.hash
			
			deserialized.speechs[i] = newSpeech
			
			initMarker(MARKER_INIT_MODE_SPEECH, newSpeech)
		end
		
		-- init answers --
		for i,v: answer.object in next, deserialized.answers do
			local marker: marker.object = deserialized.markers[v.marker]
			
			local newAnswer: answer.object = --[[new]] answer(
				marker, 
				v.text, 
				i, 
				v.nextSpeech,
				v.actionSource
			)
			
			marker.parentHash = newAnswer.hash
			
			deserialized.answers[i] = newAnswer
			
			initMarker(MARKER_INIT_MODE_ANSWER, newAnswer)
		end
		
		local newDialog: dialog.object = --[[new]] dialog(
			container, 
			deserialized.markers, 
			deserialized.speechs, 
			deserialized.answers,
			deserialized.firstSpeech
		)
		
		return newDialog
	end
	
	new.dialogEditor = dialogEditor
	new.newDialogGui = newDialogGui
	new.importDialogGui = importDialogGui
	
	return new
end

shared.toolbarConstructor = toolbar

return toolbar
