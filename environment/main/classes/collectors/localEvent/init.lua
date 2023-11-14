local SMKSignal: SMKSignal.constructor = require(script.SMKSignal)

type void = nil

type callback<T...> = (T...) -> unknown
type callbacksFun = (signal: SMKSignal.object) -> void

type callbacks<T...> = {
	[number]: SMKSignal.object,
	
	-- methods
	
	fire: callback<T...>,
	add: callbacksFun, 
	del: callbacksFun,
	iterate: (_, last: SMKSignal.object?) -> (number, SMKSignal.object)
}

type event<T...> = {
	-- properties
	
	callbacks: callbacks<T...>,
	
	-- methods
	
	connect: (callback: callback<T...>) -> SMKSignal.object<T...>
}
type eventConstructor = () -> event

export type object<T...> = event<T...>
export type constructor = eventConstructor

if shared.eventConstructor then
	return shared.eventConstructor :: eventConstructor
end

local event: eventConstructor = function()
	local new: event = {}
	
	local callbacks: callbacks = {}
	
	function callbacks.add(signal)
		table.insert(callbacks, signal)
	end
	function callbacks.del(signal)
		table.remove(callbacks, table.find(callbacks, signal))
	end
	do
		local i = 0
		function callbacks.iterate(_, last)
			if not last then i = 0 end
			i += 1
			if callbacks[i] then return i, callbacks[i] end
		end
	end
	function callbacks.fire(...)
		for _,signal in callbacks.iterate do
			coroutine.wrap(signal.callback)(...)
		end
	end
	
	new.callbacks = callbacks
	
	function new.connect(callback)
		local newSignal: SMKSignal.object = --[[new]] SMKSignal(callback, new)
		callbacks.add(newSignal)
		return newSignal
	end
	
	return new
end

shared.eventConstructor = event

return event
