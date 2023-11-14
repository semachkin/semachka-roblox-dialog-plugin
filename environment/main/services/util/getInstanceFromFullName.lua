return function(name)
	local dirs = name:split'\.'
	local parent = game
	for _,v in next, dirs do
		parent = parent:FindFirstChild(v)
		if not parent then return end
	end
	return parent
end
