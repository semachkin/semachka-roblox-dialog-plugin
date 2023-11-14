type void = nil

type keys = {[number]: any}

type SMKConnection = {
	-- properties
	
	content: any,
	keys: keys, 
	parent: unknown,
	
	-- methods
	
	disconnect: () -> void,
	isValidKeys: (...any) -> boolean
}
type SMKConnectionConstructor = (
	content: any,
	parent: unknown,
	...any
) -> SMKConnection

export type object = SMKConnection
export type constructor = SMKConnectionConstructor

if shared.SMKConnectionConstructor then
	return shared.SMKConnectionConstructor :: SMKConnectionConstructor
end

local SMKConnection: SMKConnectionConstructor = function(content, parent, ...) 
	local new: SMKConnection = {}
	
	local keys = {...}
	
	new.content = content
	new.parent = parent
	new.keys = keys
	
	function new.disconnect()
		parent.connects.del(new)
		new = nil
		keys = nil
	end
	function new.isValidKeys(...)
		local newKeys = {...}
		
		local result = true
		
		for i,v in next, keys do
			if newKeys[i] == v then continue end
			result = false
			break
		end
		
		return result
	end
	
	return new
end

shared.SMKConnectionConstructor = SMKConnection

return SMKConnection
