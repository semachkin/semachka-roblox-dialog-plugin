type void = nil

type voidFun = () -> void

type coreGui = {
	instance: ScreenGui,
	title: string,
	toolbar: unknown,
	
	open: voidFun,
	close: voidFun
}
type coreGuiConstructor = (
	toolbar: unknown,
	title: string,
	initEnabledValue: boolean
) -> coreGui

export type object = coreGui
export type constructor = coreGuiConstructor

if shared.coreGuiConstructor then
	return shared.coreGuiConstructor :: coreGuiConstructor
end

local coreGui: coreGuiConstructor = function(toolbar, title, initEnabledValue)
	local new: coreGui = {}
	
	local instance: ScreenGui = Instance.new'ScreenGui'
	
	instance.Parent = toolbar.coreGuiFolder
	instance.Name = title
	instance.Enabled = initEnabledValue
	
	function new.open()
		instance.Enabled = true
	end
	function new.close()
		instance.Enabled = false
	end
	
	new.instance = instance
	new.title = title
	
	return new
end

shared.coreGuiConstructor = coreGui

return coreGui
