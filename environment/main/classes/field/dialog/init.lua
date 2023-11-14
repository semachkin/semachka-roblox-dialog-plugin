local fieldClasses = script.Parent
local classes = fieldClasses.Parent

local marker: marker.object = require(fieldClasses.marker)
local speech: speech.object = require(script.speech)
local answer: speech.object = require(script.speech.answer)

local metatable = require(classes.metatable)

type void = nil

type markers = {[string]: marker.object}
type answers = {[string]: answer.object}
type speechs = {[string]: speech.object}

type dialog = {
	-- properties
	
	instance: BinaryStringValue,
	speechs: speechs,
	answers: answers,
	markers: markers,
	firstSpeech: string,
	dir: string,
	
	-- methods
	
	destroy: () -> void
}
type dialogConstructor = (
	instance: BinaryStringValue,
	markers: markers?,
	speechs: speechs?,
	answers: answers?,
	firstSpeech: string?
) -> dialog

--- other ---

type serializedMarkers = {[string]: marker.serializeVersion}

export type serializeVersion = {
	answers: answers,
	speechs: speechs,
	markers: serializedMarkers
}

export type object = dialog
export type constructor = dialogConstructor

if shared.dialogConstructor then
	return shared.dialogConstructor :: dialogConstructor
end

--- options ---
local entryMarkerColor, exitMarkerColor = Color3.fromHex'3d9624', Color3.fromHex'a31313'
local entryMarkerPos,   exitMarkerPos   = Vector3.new(-10, -1),   Vector3.new(5, -1)
local entryMarkerSize,  exitMarkerSize  = Vector3.new(5, 2),      Vector3.new(5, 2)

local function initMarkers(markersPtr)
	local grid = shared.grid
	
	local enterMarker: marker.object = --[[new]] marker(
		1, 
		false, 
		grid, 
		'Entry',
		entryMarkerColor, 
		entryMarkerPos, 
		entryMarkerSize, 
		nil,
		true,
		true
	)
	local exitMarker: marker.object = --[[new]] marker(
		0, 
		false, 
		grid, 
		'Exit', 
		exitMarkerColor, 
		exitMarkerPos, 
		exitMarkerSize, 
		nil,
		false,
		true
	)
	
	shared.initMarker(shared.MARKER_INIT_MODE_ENTER, enterMarker)
	
	markersPtr[enterMarker.hash] = enterMarker
	markersPtr[exitMarker.hash] = exitMarker
end

local dialog: dialogConstructor = function(
	instance, markers, speechs, answers, firstSpeech
)
	local new: dialog = {}
	
	new.markers = markers or {}
	new.speechs = speechs or {}
	new.answers = answers or {}
	new.firstSpeech = firstSpeech
	
	if not next(new.markers) then
		initMarkers(new.markers)
	end
	
	new.instance = instance
	new.dir = instance:GetFullName():sub(1, -string.len(instance.Name) - 2)
	
	function new.destroy()
		for i,v: marker.object in next, new.markers do
			v.destroy()
			new.markers[i] = nil
		end
		for i,v in next, new.speechs do
			new.speechs[i] = nil
		end
		for i,v in next, new.answers do
			new.answers[i] = nil
		end
		new = nil
	end
	
	local function serialize(hashTable)
		local result = ''
		
		for i,any in next, hashTable do
			if type(any) == 'function' or typeof(any) == 'Instance' then continue end
			
			i = tostring(i) == i and `"{i}"` or tostring(i)
			result ..= `[{i}]=`
			if type(any) == 'number' then 
				result ..= any
			elseif type(any) == 'string' then 
				result ..= `\`{('%q').format(any)}\``
			elseif type(any) == 'table' then 
				local anyString = tostring(any)
				result ..= anyString:sub(1,5) == 'table' and serialize(any) or anyString
			end
			result ..= ','
		end
		
		return `\{{result}\}`
	end
	
	local newMetatable: metatable.object = {}
	
	newMetatable.__tostring = serialize
	
	new = setmetatable(new, newMetatable)
	
	return new
end

shared.dialogConstructor = dialog

return dialog
