local SMKConnect: SMKConnect.constructor = require(script.SMKConnection)

type void = nil

type connectsFun = (connect: SMKConnect.object) -> void

type connects = {
	[number]: SMKConnect.object,
	
	-- methods
	
	add: connectsFun,
	del: connectsFun,
	iterate: (_, last: SMKConnect.object?) -> (number, SMKConnect.object)
}

type decryptor = {
	-- properties
	
	connects: connects,
	
	-- methods
	
	fire: (...any) -> any,
	connect: (content: any, ...any) -> SMKConnect.object
}
type decryptorConstructor = () -> decryptor

export type object = decryptor
export type constructor = decryptorConstructor

if shared.decryptorConstructor then
	return shared.decryptorConstructor :: decryptorConstructor
end

local decryptor: decryptorConstructor = function()
	local new: decryptor = {}
	
	local connects: connects = {}
	
	function connects.add(connect)
		table.insert(connects, connect)
	end
	function connects.del(connect)
		table.remove(connects, table.find(connects, connect))
	end
	do
		local i = 0
		function connects.iterate(_, last)
			if not last then i = 0 end
			i += 1
			if connects[i] then return i, connects[i] end
		end
	end
	
	new.connects = connects
	
	function new.fire(...)
		for _,connect in connects.iterate do
			if not connect.isValidKeys(...) then continue end
			return connect.content
		end
	end
	function new.connect(content, ...)
		local newConnect: SMKConnect.object = --[[new]] SMKConnect(content, new, ...)
		connects.add(newConnect)
		return newConnect
	end
	
	return new
end

shared.decryptorConstructor = decryptor

return decryptor
