local fieldClasses = script.Parent.Parent

local marker: marker.constructor = require(fieldClasses.marker)
local answer: answer.constructor = require(script.answer)

type answers = {[number]: string}
type words = answers

type speech = {
	hash: string,
	words: words,
	answers: answers,
	marker: string,
}
type speechConstructor = (
	marker: marker.object,
	words: words?,
	hash: string?,
	answers: answers?
) -> speech

export type object = speech
export type constructor = speechConstructor

if shared.speechConstructor then
	return shared.speechConstructor :: speechConstructor
end

local speech: speechConstructor = function(marker, words, hash, answers)
	local new: speech = {}
	
	words = words or {}
	
	marker.tag = 'speech'
	
	new.marker = marker.hash
	new.words = words
	new.answers = answers or {}
	
	new.hash = hash or tostring(new):sub(8, -1)
	
	marker.parentHash = new.hash
	
	return new
end

shared.speechConstructor = speech

return speech
