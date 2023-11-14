type void = nil

type callback<T...> = (T...) -> unknown

type SMKSignal<T...> = {
	-- properties
	
	callback: callback<T...>,
	parent: unknown,
	
	-- methods
	
	disconnect: () -> void
}
type SMKSignalConstructor = (
	callback: callback<unknown>,
	parent: unknown
) -> SMKSignal

export type object<T...> = SMKSignal<T...>
export type constructor = SMKSignalConstructor

if shared.SMKSignalConstructor then
	return shared.SMKSignalConstructor :: SMKSignalConstructor
end

local SMKSignal: SMKSignalConstructor = function(callback, parent)
	local new: SMKSignal = {}
	
	new.callback = callback
	new.parent = parent
	
	function new.disconnect()
		parent.callbacks.del(new)
		new = nil
	end
	
	return new
end

shared.SMKSignalConstructor = SMKSignal

return SMKSignal
