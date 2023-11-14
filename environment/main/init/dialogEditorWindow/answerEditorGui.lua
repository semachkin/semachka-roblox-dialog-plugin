local classes = script.Parent.Parent.Parent.classes
local fieldClasses = classes.field
local colelctorClasses = classes.collectors

--- classes ---
local answer: answer.constructor = require(fieldClasses.dialog.speech.answer)
local marker: marker.object = require(fieldClasses.marker)
local decryptor: decryptor.constructor = require(colelctorClasses.localDecryptor)

local function main(guiInstance: Frame)
	local markersDecryptor: decryptor.object = shared.markersDecryptor
	
	--- descendants ---
	local openedAnswerGui = guiInstance.openedAnswer
	local buttons = guiInstance.buttons
	local closeButton = buttons.close
	local answerBox = guiInstance.answerBox
	local actionScroll = guiInstance.actionScroll
	local actionBox: TextBox = actionScroll.actionBox
	local actionLines = actionScroll.lines
	
	--- options ---
	local openedAnswer: answer.object
	
	--- fun ---
	local function importAnswer(answer: answer.object)
		guiInstance.Visible = true
		
		local marker: marker.object = markersDecryptor.fire(answer.marker)
		
		openedAnswer = answer
		
		openedAnswerGui.Visible = true
		openedAnswerGui.Text = `Opened answer: {marker.name}`
		
		answerBox.Text = answer.text
		actionBox.Text = answer.actionSource
	end
	local function closeEditor()
		guiInstance.Visible = false
		guiInstance.Parent.Visible = false
	end
	
	--- events ---
	do
		answerBox:GetPropertyChangedSignal'Text':Connect(function() 
			if not openedAnswer then return end
			
			openedAnswer.text = answerBox.Text
		end)
		actionBox:GetPropertyChangedSignal'Text':Connect(function() 
			actionScroll.CanvasSize = UDim2.fromOffset(0, actionBox.TextBounds.Y)
			
			local newLines = ''
			local newText = actionBox.Text
			
			local lines = 0
			for _ in newText:gmatch'([^\n]*)\n?' do
				lines += 1
			end
			for i = 1, lines - 1 do
				newLines ..= `{i}\n`
			end
			
			actionLines.Text = newLines
			openedAnswer.actionSource = actionBox.ContentText
		end)
	end
	closeButton.MouseButton1Up:Connect(closeEditor)
	
	--- shared init ---
	shared.importAnswer = importAnswer
end

return main
