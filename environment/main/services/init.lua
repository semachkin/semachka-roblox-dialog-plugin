local selectionService = require(script.selection)

local util = script.util

local services = {}
do
	services.selectionService = selectionService
end

function shared.getService(service)
	return assert(services[service], `{service} is not a valid service name`)
end

shared.getInstanceFromFullName = require(util.getInstanceFromFullName)
shared.getAbsoluteGuiSize = require(util.getAbsoluteGuiSize)
shared.getAbsoluteGuiPosition = require(util.getAbsoluteGuiPosition)

return 0
