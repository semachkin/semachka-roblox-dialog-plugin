return function(gui: Frame)
	local newSize
	
	local sizeConstraint = gui:FindFirstChildOfClass'UISizeConstraint'
	
	if not gui:IsA'GuiObject' then
		return require(script)(gui.Parent)
	end
	
	if gui.Parent:IsA'DockWidgetPluginGui' then
		local absoluteSize = gui.Parent.AbsoluteSize
		
		newSize = Vector2.new(
			absoluteSize.X * gui.Size.X.Scale,
			absoluteSize.Y * gui.Size.Y.Scale
		)
	else
		newSize = require(script)(gui.Parent) * Vector2.new(
			gui.Size.X.Scale, 
			gui.Size.Y.Scale
		)
	end
	
	newSize += Vector2.new(gui.Size.X.Offset, gui.Size.Y.Offset)
	
	if sizeConstraint then
		
		newSize = Vector2.new(
			math.max(newSize.X, sizeConstraint.MinSize.X), 
			math.max(newSize.Y, sizeConstraint.MinSize.Y)
		)
		newSize = Vector2.new(
			math.min(newSize.X, sizeConstraint.MaxSize.X),
			math.min(newSize.Y, sizeConstraint.MaxSize.Y)
		)
	end

	return newSize
end
