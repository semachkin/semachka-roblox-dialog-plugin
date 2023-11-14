local selection = shared.getService'selectionService'

local gui = script.Parent.Parent.gui
local classes = script.Parent.Parent.classes
local fieldClasses = classes.field

local DIRECTION_MAX_LEN = 30

--- classes ---
local toolbar: toolbar.constructor = require(classes.toolbar)
local dialog: dialog.constructor = require(fieldClasses.dialog)


local function main(toolbar: toolbar.object)
	local guiInstance = toolbar.newDialogGui.instance
	
	local instance = gui.newDialogBackground:Clone()
	
	instance.Parent = guiInstance
	
	--- descendants ---
	local pane = instance.pane
	local content = pane.content
	local back = content.back
	local create = content.create
	local pin = content.pin
	local tabs = content.tabs
	local dialogDir = tabs.dir
	local dialogName = tabs.name
	local dialogDirBox = dialogDir.box
	local dialogNameBox = dialogName.box
	local dialogDirEditable = dialogDirBox.editable
	local close = pin.close
	local createButton = create.button
	local backButton = back.button
	
	--- properties ---
	local entryMarkerColor, exitMarkerColor = Color3.fromHex'5bb655', Color3.fromHex'ba0600'
	local entryMarkerSize, entryMarkerPos = Vector2.new(6,3), Vector3.new(-10, 0)
	local exitMarkerSize, exitMarkerPos = Vector2.new(6, 3), Vector3.new(4, 0)
	
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
	local function createDialog()
		local dir = dialogDirBox:GetAttribute'direction'
		if not dir then return end
		
		local parent = shared.getInstanceFromFullName(dir)
		if not parent then return warn'invalid direction' end
		
		local instance = Instance.new'BinaryStringValue'
		
		instance.Name = dialogNameBox.Text
		instance.Parent = parent
		instance:AddTag'dialog'
		
		local newDialog: dialog.object = --[[new]] dialog(instance)
		
		instance:SetAttribute('script', tostring(newDialog))
		
		newDialog.destroy()
		newDialog = nil
		
		shared.importDialog(instance)
	end
	
	--- events ---
	close.MouseButton1Up:Connect(toolbar.newDialogGui.close)
	backButton.MouseButton1Up:Connect(toolbar.newDialogGui.close)
	createButton.MouseButton1Up:Connect(toolbar.newDialogGui.close)
	dialogDirEditable.MouseButton1Up:Connect(uneditableDir)
	createButton.MouseButton1Up:Connect(createDialog)
	
	updateDir()
	selection.changed:Connect(updateDir)
end

return main
