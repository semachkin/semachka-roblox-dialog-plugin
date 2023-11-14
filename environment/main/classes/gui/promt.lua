local gui = script.Parent.Parent.Parent.gui
local patterns = gui.patterns

local promtPattern = patterns.promt

type void = nil

type voidFun = () -> void

type promt = {
	target: GuiButton,
	instance: TextLabel,
	
	open: voidFun,
	close: voidFun
}
type promtConstructor = (
	target: GuiButton,
	title: string
) -> promt

export type object = promt
export type constructor = promtConstructor

local WAIT_TO_VISIBLE_PROMT = 1

if shared.promtConstructor then
	return shared.promtConstructor :: promtConstructor
end

local promt: promtConstructor = function(target, title)
	local new: promt = {}
	
	local instance: TextLabel = promtPattern:Clone()
	
	local gui = target:FindFirstAncestorOfClass'DockWidgetPluginGui'
	
	instance.Parent = gui
	
	instance.Text = title
	instance.Size = UDim2.fromOffset(
		instance.TextBounds.X,
		instance.Size.Y.Offset
	)
	
	instance.Visible = false
	instance.TextTransparency = 1
	instance.BackgroundTransparency = 1
	
	local thread: thread
	
	local function newThread(callback)
		if thread then coroutine.close(thread) end
		thread = coroutine.create(callback)
		coroutine.resume(thread)
	end
	
	function new.open()
		local mousePos = gui:GetRelativeMousePosition()
		
		instance.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
		
		instance.Visible = true
		newThread(function() 
			local delta = instance.BackgroundTransparency
			for i = delta, 0, -3e-2 do
				instance.BackgroundTransparency = i
				instance.TextTransparency = i
				task.wait()
			end
		end)
	end
	function new.close()
		newThread(function() 
			local delta = instance.BackgroundTransparency
			for i = delta, 1, 3e-2 do
				instance.BackgroundTransparency = i
				instance.TextTransparency = i
				task.wait()
			end
			instance.Visible = false
		end)
	end
	
	target.MouseEnter:Connect(function() 
		local leaved
		
		coroutine.wrap(function() 
			target.MouseLeave:Wait()
			leaved = true
		end)()
		
		wait(WAIT_TO_VISIBLE_PROMT)
		if leaved then return end
		
		new.open()
		repeat task.wait() until leaved
		
		new.close()
	end)
	
	new.target = target
	new.instance = instance
	
	return new
end

shared.promtConstructor = promt

return promt
