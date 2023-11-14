local classes = script.Parent.Parent.Parent.classes
local fieldClasses = classes.field
local colelctorClasses = classes.collectors

--- classes ---
local speech: speech.object = require(fieldClasses.dialog.speech)
local marker: marker.object = require(fieldClasses.marker)
local decryptor: decryptor.constructor = require(colelctorClasses.localDecryptor)

local function main(guiInstance: Frame)
	local markersDecryptor: decryptor.object = shared.markersDecryptor
	
	--- descendants ---
	local buttons = guiInstance.buttons
	local words = guiInstance.words
	local openedSpeechGui = guiInstance.openedSpeech
	local wordPattern = words.pattern
	local addButton = buttons.add
	local closeButton = buttons.close
	
	--- options ---
	local openedSpeech: speech.object
	
	--- fun ---
	local function clearWords()
		for _,v in next, words:GetChildren() do
			if v.Name:sub(1, 4) == 'word' then
				v.Parent = nil
			end
		end
	end
	local function newWord(_, _, text, importMode, index)
		local newFrame = wordPattern:Clone()
		
		text = text or ''
		
		newFrame.Parent = words
		newFrame.Visible = true
		
		if not importMode then
			table.insert(openedSpeech.words, text)
		end
		
		local index = importMode and index or #openedSpeech.words
		
		newFrame.index.Text = index
		newFrame.Name = `word{index}`
		newFrame:SetAttribute('index', index)
		
		local box: TextBox = newFrame.box
		
		box.Text = text
		box:GetPropertyChangedSignal'Text':Connect(function() 
			index = newFrame:GetAttribute'index'
			openedSpeech.words[index] = box.Text
			text = box.Text
		end)
		newFrame.del.MouseButton1Up:Connect(function() 
			index = newFrame:GetAttribute'index'
			newFrame.Parent = nil
			
			for i = index + 1, #openedSpeech.words do
				local word = words[`word{i}`]
				
				index = i - 1
				word.index.Text = index
				word:SetAttribute('index', index)
				word.Name = `word{index}`
			end
			
			table.remove(openedSpeech.words, index)
		end)
		
		return newFrame
	end
	local function importSpeech(speech: speech.object)
		guiInstance.Visible = true
		
		local marker: marker.object = markersDecryptor.fire(speech.marker)
		
		openedSpeech = speech
		
		openedSpeechGui.Visible = true
		openedSpeechGui.Text = `Opened speech: {marker.name}`
		
		clearWords()
		
		for i,v in next, speech.words do
			newWord(0, 0, v, true, i)
		end
	end
	local function closeEditor()
		guiInstance.Visible = false
		guiInstance.Parent.Visible = false
	end
	
	--- events ---
	addButton.MouseButton1Up:Connect(newWord)
	closeButton.MouseButton1Up:Connect(closeEditor)
	
	--- shared init ---
	shared.importSpeech = importSpeech
end

return main
