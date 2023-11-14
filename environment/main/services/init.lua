local selectionService = require(script.selection)

local functions = script.functions

local services = {}
do
	services.selectionService = selectionService
end

function shared.getService(service)
	return assert(services[service], `{service} is not a valid service name`)
end

shared.getInstanceFromFullName = require(functions.getInstanceFromFullName)
shared.getAbsoluteGuiSize = require(functions.getAbsoluteGuiSize)
shared.getAbsoluteGuiPosition = require(functions.getAbsoluteGuiPosition)

return 0
