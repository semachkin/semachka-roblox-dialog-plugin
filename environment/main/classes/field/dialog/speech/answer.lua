local fieldClasses = script.Parent.Parent.Parent

local marker: marker.constructor = require(fieldClasses.marker)

type void = nil

type answer = {
	text: string,
	marker: string,
	hash: string,
	nextSpeech: string,
	actionSource: string
}
type answerConstructor = (
	marker: marker.object,
	text: string?,
	hash: string?,
	nextSpeech: string?
) -> answer

export type object = answer
export type constructor = answerConstructor

if shared.answerConstructor then
	return shared.answerConstructor :: answerConstructor
end

local answer: answerConstructor = function(
	marker, text, hash, nextSpeech, actionSource
)
	local new: answer = {}
	
	text = text or ''
	actionSource = actionSource or ''
	
	marker.tag = 'answer'
	
	new.text = text
	new.marker = marker.hash
	new.nextSpeech = nextSpeech
	new.actionSource = actionSource
	
	new.hash = hash or tostring(new):sub(8, -1)
	
	marker.parentHash = new.hash
	
	return new
end

shared.answerConstructor = answer

return answer
