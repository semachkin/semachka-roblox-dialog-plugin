local selection = shared.getService'selectionService'

local gui = script.Parent.Parent.gui
local classes = script.Parent.Parent.classes

local DIRECTION_MAX_LEN = 30

--- classes ---
local toolbar: toolbar.constructor = require(classes.toolbar)

local function main(toolbar: toolbar.object)
	local guiInstance = toolbar.importDialogGui.instance
	
	local instance = gui.importDialogBackground:Clone()
	
	instance.Parent = guiInstance
	
	-- descendants --
	local pane = instance.pane
	local content = pane.content
	local back = content.back
	local import = content.import
	local pin = content.pin
	local dialogDir = content.dir
	local dialogDirBox = dialogDir.box
	local dialogDirEditable = dialogDirBox.editable
	local close = pin.close
	local importButton = import.button
	local backButton = back.button
	
	--- fun ---
	local function updateDir()
		if dialogDirBox.TextEditable then return end
		
		task.wait()
		local selected = selection.selected
		if not selected then return end

		local dir = selected:GetFullName()
		local dirLen = string.len(dir)
		dialogDirBox:SetAttribute('direction', dir)

		if dirLen > DIRECTION_MAX_LEN then
			dir = `...{dir:sub(-DIRECTION_MAX_LEN, dirLen)}`
		end

		dialogDirBox.Text = dir
	end
	local function uneditableDir()
		local editable = dialogDirBox.TextEditable
		dialogDirEditable.ImageTransparency = editable and 0 or .5
		dialogDirBox.TextEditable = not editable
		if editable then updateDir() end
	end
	local function importDialog()
		local dir = dialogDirBox:GetAttribute'direction'
		if not dir then return end

		local dialog: Instance = shared.getInstanceFromFullName(dir)
		if not dialog then return warn'invalid direction' end
		
		if not dialog:IsA'BinaryStringValue' then return warn'invalid instance' end
		
		shared.importDialog(dialog)
	end
	
	-- events--
	close.MouseButton1Up:Connect(toolbar.importDialogGui.close)
	backButton.MouseButton1Up:Connect(toolbar.importDialogGui.close)
	importButton.MouseButton1Up:Connect(toolbar.importDialogGui.close)
	dialogDirEditable.MouseButton1Up:Connect(uneditableDir)
	importButton.MouseButton1Up:Connect(importDialog)
	
	updateDir()
	selection.changed:Connect(updateDir)
end

return main
