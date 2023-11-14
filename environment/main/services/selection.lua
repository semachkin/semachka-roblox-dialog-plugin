local selection = game:GetService'Selection'

local selectionService = {} do
	
	local function updateSelected()
		selectionService.selected = selection:Get()[1]
	end
	
	selectionService.changed = selection.SelectionChanged
	
	selectionService.changed:Connect(updateSelected)
end

return selectionService
