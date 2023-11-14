local classes = script.Parent.Parent
local gui = script.Parent.Parent.Parent.gui
local patterns = gui.patterns

local sectionsPattern = patterns.sections
local sectionButtonPattern = patterns.sectionButton

type void = nil
type voidFun = () -> void

type sections = {[string]: TextButton}

type preInitSection = {
	title: string, 
	icon: string
}

type pin = {
	button: TextButton,
	instance: CanvasGroup,
	sections: sections,
	enabled: boolean,
	
	open: voidFun,
	close: voidFun,
	debounced: (callback: (...any) -> unknown) -> (...any)
}
type pinConstructor = (
	button: TextButton,
	sections: {[string]: preInitSection},
	rightClick: boolean?
) -> pin

export type object = pin
export type constructor = pinConstructor

if shared.pinConstructor then
	return shared.pinConstructor :: pinConstructor
end

local pin: pinConstructor = function(button, sections, rightClick)
	local new: pin = {}
	
	local instance: CanvasGroup = patterns.sections:Clone()
	
	--- init ---
	instance.Parent = button
	instance.GroupTransparency = 1
	instance.Visible = false
	
	local newSections: sections = {}
	
	--- constructors ---
	local function sectionEnter(section: TextButton)
		return function()
			section.BackgroundTransparency = .5
		end
	end
	local function sectionLeave(section: TextButton)
		return function()
			section.BackgroundTransparency = 1
		end
	end
	
	local sectionsLength = 0
	
	for i,section: preInitSection in next, sections do
		local newSection = sectionButtonPattern:Clone()
		
		newSection.Parent = instance
		newSection.Text = section.title
		newSection.icon.Image = section.icon
		
		newSection.MouseEnter:Connect(sectionEnter(newSection))
		newSection.MouseLeave:Connect(sectionLeave(newSection))
		
		newSections[i] = newSection
		
		sectionsLength += 1
	end
	
	instance.Size = UDim2.fromOffset(
		instance.Size.X.Offset,
		sectionsLength * sectionButtonPattern.Size.Y.Offset + 5
	)
	
	local thread, leaveWaitThread: thread
	
	local function newThread(callback)
		if thread then coroutine.close(thread) end
		thread = coroutine.create(callback)
		coroutine.resume(thread)
	end
	
	function new.open()
		instance.Visible = true
		newThread(function()
			local delta = instance.GroupTransparency
			for i = delta, 0, -7e-2 do
				instance.GroupTransparency = i
				task.wait()
			end
			instance.GroupTransparency = 0
		end)
		new.enabled = true
	end
	function new.close()
		newThread(function()
			local delta = instance.GroupTransparency
			for i = delta, 1, 7e-2 do
				instance.GroupTransparency = i
				task.wait()
			end
			instance.GroupTransparency = 1
		end)
		new.enabled = false
		instance.Visible = false
		if leaveWaitThread then
			coroutine.yield(leaveWaitThread)
			coroutine.close(leaveWaitThread)
		end
	end
	
	local function open() 
		if new.enabled then
			new.close()
		else
			new.open()
			leaveWaitThread = coroutine.create(function() 
				instance.MouseEnter:Wait()
				instance.MouseLeave:Wait()
				new.close()
			end)
			coroutine.resume(leaveWaitThread)
		end
	end
	
	if rightClick then
		button.MouseButton2Up:Connect(open)
	else
		button.MouseButton1Up:Connect(open)
	end
	
	function new.debounced(callback)
		return function(...)
			if new.enabled then return end
			callback(...)
		end
	end
	
	new.enabled = false
	new.button = button
	new.instance = instance
	new.sections = newSections
	
	return new
end

shared.pinConstructor = pin

return pin
