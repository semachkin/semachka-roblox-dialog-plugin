local gui = script.Parent.Parent.gui
local classes = script.Parent.Parent.classes
local guiClasses = classes.gui
local fieldClasses = classes.field
local collectorClasses = classes.collectors

--- classes ---
local toolbar: toolbar.constructor = require(classes.toolbar)
local pin: pin.constructor = require(guiClasses.pin)
local promt: promt.constructor = require(guiClasses.promt)
local dialog: dialog.constructor = require(fieldClasses.dialog)
local speech: speech.constructor = require(fieldClasses.dialog.speech)
local answer: answer.constructor = require(fieldClasses.dialog.speech.answer)
local marker: marker.constructor = require(fieldClasses.marker)
local decryptor: decryptor.constructor = require(collectorClasses.localDecryptor)
local NVector2: NVector2.constructor = require(classes.NVector2)

--- decryptors ---
local markersDecryptor: decryptor.object = shared.markersDecryptor

--- properties ---
local cellSize = shared.cellSize
local maxSpeechOutputs = 0xFFFFFF
local maxAnswerOutputs = 0xFFFFFF
local startSpeechColor = Color3.fromHex'81a7ff'
local startAnswerColor = Color3.fromHex'ffff7b'
local startSpeechSize  = Vector2.new(8, 2)
local startAnswerSize  = Vector2.new(5, 2)

local speechTagsWhitelist = {
	answer   = true,
	untagged = true,
	speech   = true
}
local answerTagsWhitelist = {
	untagged = true,
	speech   = true
}
local enterTagsWhitelist = {
	speech = true,
	answer = true
}

local MARKER_INIT_MODE_SPEECH = 0x0001
local MARKER_INIT_MODE_ENTER  = 0x0002
local MARKER_INIT_MODE_ANSWER = 0x0003

local initSpeechEditorGui = require(script.speechEditorGui)
local initAnswerEditorGui = require(script.answerEditorGui)

local function main(toolbar: toolbar.object)
	local window = toolbar.dialogEditor.instance
	
	local instance = gui.dialogEditorBackground:Clone()
	
	instance.Parent = window

	--- descendants ---
	local openedDialogGui = instance.openedDialog
	local savingText = instance.saving
	local pins = instance.pins
	local buttons = instance.buttons
	local field = instance.field
	local grid = field.grid
	local gridMover = grid.mover
	local tabs = instance.tabs
	local editors = instance.editors
	local speechEditor = editors.speechEditor
	local answerEditor = editors.answerEditor
	
	local colorPicker = instance.colorPicker
	local colorPickerContent = colorPicker.pane.content
	local colorPickerCancel = colorPickerContent.cancel
	local colorPickerDone = colorPickerContent.done
	local colorHexBar = colorPickerContent.hexBar
	local colorHSVComponents = colorPickerContent.hsvComponents
	local colorRGBComponents = colorPickerContent.rgbComponents
	local colorPalette = colorPickerContent.palette
	local colorLightness = colorPickerContent.lightness
	local colorDoneButton = colorPickerDone.button
	local colorCacelButton = colorPickerCancel.button
	local colorPattern = colorPickerContent.pattern
	
	--- options ---
	local dialogSections = {
		new    = {title = 'New...',           icon = 'rbxassetid://15127893499'},
		save   = {title = 'Save...',          icon = 'rbxassetid://15126658186'},
		import = {title = 'Import...',        icon = 'rbxassetid://15126660322'},
		close  = {title = 'Close dialog...',  icon = ''},
	}
	local markerSections = {
		speech = {title = 'New speech...', icon = ''},
		answer = {title = 'New answer...', icon = ''},
	}
	local openedDialog: dialog.object
	local selectedColor: Color3
	local colorChangable = true
	
	--- pins ---
	local dialogPin: pin.object = --[[new]] pin(pins.dialog, dialogSections)
	local markerPin: pin.object = --[[new]] pin(pins.markers, markerSections)
	
	--- promts ---
	local newDialogPromt: promt.object = --[[new]] promt(buttons.newDialog, 'New Dialog...')
	
	local addSpeechPromt: promt.object = --[[new]] promt(tabs.addSpeech, 'Add Speech...')
	local addAnswerPromt: promt.object = --[[new]] promt(tabs.addAnswer, 'Add Answer...')
	
	--- fun ---
	local function resetGrid()
		grid.CanvasPosition = grid.AbsoluteCanvasSize/2 - grid.AbsoluteWindowSize/2
	end
	local function checkDialogForValid(deserialized: dialog.serializeVersion)
		if type(deserialized) ~= 'table' then return end
		
		local answers = deserialized.answers
		if type(answers) ~= 'table' then return end
		
		local speechs = deserialized.speechs
		if type(speechs) ~= 'table' then return end
		
		local markers = deserialized.markers
		
		if type(markers) ~= 'table' then return end
		if not next(markers) then return end
		
		return true
	end
	local function importDialog(container: BinaryStringValue)
		local serializedDialog = container:GetAttribute'script'
		
		local result, deserializedDialog = xpcall(function() 
			return loadstring(`return {serializedDialog}`)()
		end, function() 
			warn(`error importing {instance}`)
		end)
		if not result then return end
		
		if not checkDialogForValid(deserializedDialog) then return end
		
		local newDialog: dialog.object = toolbar.importDialog(deserializedDialog, container)
		resetGrid()
		
		openedDialogGui.Visible = true
		openedDialogGui.Text = `Opened dialog: {container}`
		
		openedDialog = newDialog
	end
	local function saveDialog()
		if not openedDialog then return warn'impossible to save a not open dialog' end
		
		savingText.Visible = true
		
		local serialized = tostring(openedDialog)
		
		local openedInstance = openedDialog.instance
		
		if openedInstance.Parent then
			openedInstance:SetAttribute('script', serialized)
		else
			local newDialog = Instance.new'BinaryStringValue'
			
			newDialog.Parent = shared.getInstanceFromFullName(openedDialog.dir)
			newDialog.Name = openedInstance.Name
			newDialog:SetAttribute('script', serialized)
			
			openedDialog.instance = newDialog
		end
		
		savingText.Visible = false
	end
	local function moveGrid()
		local pressed = true
		
		task.spawn(function() 
			local beta = window:GetRelativeMousePosition()
			repeat task.wait()
				local alpha = window:GetRelativeMousePosition()
				
				local delta = beta - alpha
				grid.CanvasPosition += delta
				
				beta = alpha
			until not pressed
		end)
		
		gridMover.MouseButton2Up:Wait()
		pressed = false
	end
	local function clearGrid()
		openedDialogGui.Visible = false
		
		if openedDialog then
			openedDialog.destroy()
			openedDialog = nil
		end
	end
	local function initMarker(mode, ...)
		if mode == MARKER_INIT_MODE_SPEECH then
			local speech = (...) :: speech.object
			
			local marker: marker.object = markersDecryptor.fire(speech.marker)
			
			local function openSpeech()
				editors.Visible = true

				shared.importSpeech(speech)
			end
			
			marker.doubleClicked.connect(openSpeech)
			marker.pin.sections.edit.MouseButton1Up:Connect(openSpeech)
			
			marker.outputAdded.connect(function(newOutput) 
				if not speechTagsWhitelist[newOutput.ancestor.tag] then
					marker.delOutput(newOutput)
					return
				end
				table.insert(speech.answers, newOutput.ancestor.parentHash)
			end)
			marker.outputRemoved.connect(function(lastOutput)
				local index = table.find(speech.answers, lastOutput.ancestor.parentHash)
				
				if index then
					table.remove(speech.answers, index)
				end
			end)
			marker.destroyed.connect(function() 
				openedDialog.markers[marker.hash] = nil
				openedDialog.speechs[speech.hash] = nil
				marker = nil
			end)
		elseif mode == MARKER_INIT_MODE_ENTER then
			local marker = (...) :: marker.object
			
			marker.outputAdded.connect(function(newOutput) 
				if not enterTagsWhitelist[newOutput.ancestor.tag] then
					marker.delOutput(newOutput)
					return
				end
				openedDialog.firstSpeech = newOutput.ancestor.parentHash
			end)
			marker.outputRemoved.connect(function(lastOutput) 
				if openedDialog.firstSpeech == lastOutput.ancestor.parentHash then
					openedDialog.firstSpeech = nil
				end
			end)
		elseif mode == MARKER_INIT_MODE_ANSWER then
			local answer = (...) :: answer.object
			
			local marker: marker.object = markersDecryptor.fire(answer.marker)
			
			local function openAnswer()
				editors.Visible = true
				
				shared.importAnswer(answer)
			end
			
			marker.doubleClicked.connect(openAnswer)
			marker.pin.sections.edit.MouseButton1Up:Connect(openAnswer)
			
			marker.outputAdded.connect(function(newOutput) 
				if not answerTagsWhitelist[newOutput.ancestor.tag] then
					marker.delOutput(newOutput)
					return
				end
				answer.nextSpeech = newOutput.ancestor.parentHash
			end)
			marker.outputRemoved.connect(function(lastOutput) 
				if answer.nextSpeech == lastOutput.ancestor.parentHash then
					answer.nextSpeech = nil
				end
			end)
			marker.destroyed.connect(function() 
				openedDialog.answers[answer.hash] = nil
				openedDialog.markers[marker.hash] = nil
				marker = nil
			end)
		end
	end
	local function setPickerColor(color: Color3)
		local h, s, v = color:ToHSV()
		
		local palettePosition = UDim2.fromScale(h, 1 - s)
		local lightnessPosition = UDim2.fromScale(v, 0)
		
		colorPalette.point.Position = palettePosition
		colorLightness.point.Position = lightnessPosition
		
		colorChangable = false
		colorHSVComponents.H.Text = math.round(h * 0x167)
		colorHSVComponents.S.Text = math.round(s * 0xFF)
		colorHSVComponents.V.Text = math.round(v * 0xFF)
		
		colorRGBComponents.R.Text = math.round(color.R * 0xFF)
		colorRGBComponents.G.Text = math.round(color.G * 0xFF)
		colorRGBComponents.B.Text = math.round(color.B * 0xFF)
		
		colorHexBar.Text = `#{color:ToHex()}`
		colorChangable = true
		
		selectedColor = color
		
		colorPattern.BackgroundColor3 = selectedColor
	end
	local function selectColor(startColor: Color3?, position: Vector2?)
		colorPicker.Visible = true
		
		if position then
			local absolutePosition = Vector2.new(
				position.X + colorPicker.AbsoluteSize.X,
				position.Y + colorPicker.AbsoluteSize.Y
			)
			local offsetX, offsetY = 0, 0
			
			if absolutePosition.X > window.AbsoluteSize.X then
				offsetX = absolutePosition.X - window.AbsoluteSize.X
			end
			if absolutePosition.Y > window.AbsoluteSize.Y then
				offsetY = absolutePosition.Y - window.AbsoluteSize.Y
			end
			
			position = UDim2.fromOffset(position.X - offsetX, position.Y - offsetY)
		end
		
		local position = position or UDim2.fromOffset(.5, .5)
		colorPicker.Position = position
		
		startColor = Color3.new(startColor.R, startColor.G, startColor.B)
		
		setPickerColor(startColor)
		
		local apply, cancel
		local applyEvent, cancelEvent
		
		applyEvent = colorDoneButton.MouseButton1Up:Connect(function() 
			apply = true
		end)
		cancelEvent = colorCacelButton.MouseButton1Up:Connect(function() 
			cancel = true
		end)
		repeat task.wait() until apply or cancel
		
		colorPicker.Visible = false
		
		applyEvent:Disconnect()
		cancelEvent:Disconnect()
		
		return cancel and startColor or apply and selectedColor
	end
	local function pickPaletteColor(x, y)
		local absolutePosition = Vector2.new(x, y)
		
		local position = absolutePosition - colorPalette.AbsolutePosition
		
		local h = position.X/colorPalette.AbsoluteSize.X
		local s = 1 - position.Y/colorPalette.AbsoluteSize.Y
		local v = select(3, selectedColor:ToHSV())
		
		setPickerColor(Color3.fromHSV(h, s, v))
	end
	local function pickLightnessColor(x)
		local h, s, v = selectedColor:ToHSV()
		
		x -= colorLightness.AbsolutePosition.X
		v = x/colorLightness.AbsoluteSize.X
		
		setPickerColor(Color3.fromHSV(h, s, v))
	end
	local function updateHSVColor()
		if not colorChangable then return end
		
		local h = tonumber(colorHSVComponents.H.Text)
		local s = tonumber(colorHSVComponents.S.Text)
		local v = tonumber(colorHSVComponents.V.Text)
		
		if not h or not s or not v then return end
		
		if h > 0x169 or h < 0 then return end
		if s > 0xFF or s < 0 then return end
		if v > 0xFF or s < 0 then return end
		
		local newColor = Color3.fromHSV(h/0x167, s/0xFF, v/0xFF)
		
		setPickerColor(newColor)
	end
	local function updateRGBColor()
		if not colorChangable then return end
		
		local r = tonumber(colorRGBComponents.R.Text)
		local g = tonumber(colorRGBComponents.G.Text)
		local b = tonumber(colorRGBComponents.B.Text)
		
		if not r or not g or not b then return end
		
		if r > 0xFF or r < 0 then return end
		if g > 0xFF or g < 0 then return end
		if b > 0xFF or b < 0 then return end
		
		local newColor = Color3.fromRGB(r, g, b)
		
		setPickerColor(newColor)
	end
	local function updateHEXColor()
		if not colorChangable then return end
		
		local status, result = pcall(function() 
			return Color3.fromHex(colorHexBar.Text)
		end)
		
		if not status then return end
		
		setPickerColor(result)
	end
	
	-- markers fun ---
	local function canCreateMarkers()
		if not openedDialog then
			return warn'need to open dialog'
		end
		return true
	end
	local function getScreenPosition()
		local position = --[[new]] NVector2(0, 0)
		
		position += grid.CanvasPosition
		position += grid.AbsoluteWindowSize/2
		position -= grid.AbsoluteCanvasSize/2
		position *= Vector2.new(1, -1)
		position //= cellSize
		position -= Vector2.yAxis
		
		return position.toVector2()
	end
	local function newSpeech()
		if not canCreateMarkers() then return end
		
		local screenPosition = getScreenPosition()
		
		local newMarker: marker.object = --[[new]] marker(
			maxSpeechOutputs, 
			true, 
			grid, 
			'New speech', 
			startSpeechColor, 
			screenPosition, 
			startSpeechSize
		)
		local newSpeech: speech.object = --[[new]] speech(newMarker)
		
		initMarker(MARKER_INIT_MODE_SPEECH, newSpeech)
		
		openedDialog.markers[newMarker.hash] = newMarker
		openedDialog.speechs[newSpeech.hash] = newSpeech
	end
	local function newAnswer()
		if not canCreateMarkers() then return end
		
		local screenPosition = getScreenPosition()
		
		local newMarker: marker.object = --[[new]] marker(
			maxAnswerOutputs,
			true,
			grid,
			'New answer',
			startAnswerColor,
			screenPosition,
			startAnswerSize
		)
		local newAnswer: answer.object = --[[new]] answer(newMarker)
		
		initMarker(MARKER_INIT_MODE_ANSWER, newAnswer)
		
		openedDialog.markers[newMarker.hash] = newMarker
		openedDialog.answers[newAnswer.hash] = newAnswer
	end
	
	--- events ---
	buttons.newDialog.MouseButton1Up:Connect(toolbar.newDialogGui.open)
	dialogPin.sections.new.MouseButton1Up:Connect(toolbar.newDialogGui.open)
	dialogPin.sections.import.MouseButton1Up:Connect(toolbar.importDialogGui.open)
	dialogPin.sections.save.MouseButton1Up:Connect(saveDialog)
	dialogPin.sections.close.MouseButton1Up:Connect(clearGrid)
	gridMover.MouseButton2Down:Connect(moveGrid)
	tabs.addSpeech.MouseButton1Up:Connect(newSpeech)
	tabs.addAnswer.MouseButton1Up:Connect(newAnswer)
	markerPin.sections.speech.MouseButton1Up:Connect(newSpeech)
	markerPin.sections.answer.MouseButton1Up:Connect(newAnswer)
	colorPalette.MouseButton1Down:Connect(pickPaletteColor)
	colorPalette.MouseButton1Up:Connect(pickPaletteColor)
	colorLightness.MouseButton1Down:Connect(pickLightnessColor)
	colorLightness.MouseButton1Up:Connect(pickLightnessColor)
	
	colorHexBar:GetPropertyChangedSignal'Text':Connect(updateHEXColor)
	colorHSVComponents.H:GetPropertyChangedSignal'Text':Connect(updateHSVColor)
	colorHSVComponents.S:GetPropertyChangedSignal'Text':Connect(updateHSVColor)
	colorHSVComponents.V:GetPropertyChangedSignal'Text':Connect(updateHSVColor)
	colorRGBComponents.R:GetPropertyChangedSignal'Text':Connect(updateRGBColor)
	colorRGBComponents.G:GetPropertyChangedSignal'Text':Connect(updateRGBColor)
	colorRGBComponents.B:GetPropertyChangedSignal'Text':Connect(updateRGBColor)
	
	--- shared init ---
	shared.grid = grid
	shared.importDialog = importDialog
	shared.clearGrid = clearGrid
	shared.initMarker = initMarker
	shared.selectColor = selectColor
	
	shared.MARKER_INIT_MODE_SPEECH = MARKER_INIT_MODE_SPEECH
	shared.MARKER_INIT_MODE_ENTER  = MARKER_INIT_MODE_ENTER
	shared.MARKER_INIT_MODE_ANSWER = MARKER_INIT_MODE_ANSWER
	
	--- init ---
	resetGrid()
	initSpeechEditorGui(speechEditor)
	initAnswerEditorGui(answerEditor)
end

return main
