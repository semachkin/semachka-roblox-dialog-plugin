local getGuiSize = require(script.Parent.getAbsoluteGuiSize)

local function getAbsoluteAnchorPoint(gui: Frame)
	if not gui:IsA'GuiObject' then
		return getAbsoluteAnchorPoint(gui.Parent)
	else
		return gui.AnchorPoint
	end
end
local function findAbsoluteParent(gui: Frame)
	if not gui.Parent then return end
	if gui.Parent:IsA'GuiObject' then
		return gui.Parent
	else
		return findAbsoluteParent(gui.Parent)
	end
end

return function(gui: Frame, offset)
	local result

	offset = offset or Vector2.zero
	if not gui:IsA'GuiObject' then
		return require(script)(gui.Parent)
	end

	local scaleVector = Vector2.new(gui.Position.X.Scale, gui.Position.Y.Scale)
	local offsetVector = Vector2.new(gui.Position.X.Offset, gui.Position.Y.Offset)

	if gui.Parent:IsA'DockWidgetPluginGui' then
		local absoluteSize = gui.Parent.AbsoluteSize

		result = absoluteSize * scaleVector
	else
		local parentPosition = require(script)(gui.Parent)
		local parentSize = getGuiSize(gui.Parent)
		local anchorPoint = getAbsoluteAnchorPoint(gui.Parent)
		local guiSize = getGuiSize(gui)

		result = parentPosition + parentSize * scaleVector
		result -= parentSize * anchorPoint
		result += guiSize * offset
	end

	result += offsetVector
	
	local scrollingFrame = findAbsoluteParent(gui)
	if scrollingFrame and scrollingFrame:IsA'ScrollingFrame' then
		result -= scrollingFrame.CanvasPosition
	end

	return result
end
