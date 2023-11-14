type void = nil

type voidFun = () -> void

type window = {
	button: PluginToolbarButton,
	instance: DockWidgetPluginGui,
	guiInfo: DockWidgetPluginGuiInfo,
	toolbar: unknown,
	
	changeVisible: voidFun,
	open: voidFun,
	close: voidFun
}
type windowConstructor = (
	toolBar: unknown,
	createButton: boolean,
	windowName: string,
	windowSize: Vector2,
	windowIcon: string?
) -> window

export type object = window
export type constructor = windowConstructor

if shared.windowConstructor then
	return shared.windowConstructor :: windowConstructor
end

local window: windowConstructor = function(toolbar, createButton, name, size, icon)
	local new: window = {}
	
	local button: PluginToolbarButton
	local guiInfo: DockWidgetPluginGuiInfo
	local instance: DockWidgetPluginGui
	
	do
		if createButton then
			button = toolbar.instance:CreateButton(
				name, 
				name, 
				icon
			)
		end
		guiInfo = DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Float,
			false,
			true,
			size.X,
			size.Y,
			size.X,
			size.Y
		)
		instance = toolbar.plugin:CreateDockWidgetPluginGui(
			name, 
			guiInfo
		)
	end
	
	function new.open()
		instance.Enabled = true
	end
	function new.close()
		instance.Enabled = false
	end
	
	function new.changeVisible()
		if instance.Enabled then
			new.close()
		else
			new.open()
		end
	end
	
	if button then
		button.Click:Connect(new.changeVisible)
	end
	
	instance.Title = name
	instance.Name = name
	instance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	new.button = button
	new.guiInfo = guiInfo
	new.instance = instance
	new.toolbar = toolbar
	
	return new
end

shared.windowConstructor = window

return window
