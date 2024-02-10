local classes = script.Parent

local metatable = require(classes.metatable)

type void = nil

type NVector2 = {
	-- properties
	
	x: number,
	y: number,
	
	-- methods
	
	toVector2: () -> Vector2
}
type NVector2Constructor = (
	x: number,
	y: number
) -> NVector2

export type object = NVector2
export type constructor = NVector2Constructor

if shared.NVector2Constructor then
	return shared.NVector2Constructor :: NVector2Constructor
end

local NVector2: NVector2Constructor

NVector2 = function(x, y)
	local new: NVector2 = {}
	
	new.x = x or 0
	new.y = y or 0
	
	-- fun --
	local function operr(op)
		return `attempt to {op} a NVector2 with an incompatible value type or nil`
	end
	local function typeofnvector2(object)
		return (pcall(function() 
			object.x = object.x
			object.y = object.y
		end))
	end
	local function sumNVector2(vector: NVector2, object: any)
		local result
		
		if typeofnvector2(object) then
			result = NVector2(vector.x + object.x, vector.y + object.y)
		elseif typeof(object) == 'Vector2' then
			result = NVector2(vector.x + object.X, vector.y + object.Y)
		end
		
		return assert(result, operr'sum')
	end
	local function subNVector2(vector: NVector2, object: any)
		local result

		if typeofnvector2(object) then
			result = NVector2(vector.x - object.x, vector.y - object.y)
		elseif typeof(object) == 'Vector2' then
			result = NVector2(vector.x - object.X, vector.y - object.Y)
		end

		return assert(result, operr'sub')
	end
	local function mulNVector2(vector: NVector2, object: any)
		local result

		if typeofnvector2(object) then
			result = NVector2(vector.x * object.x, vector.y * object.y)
		elseif typeof(object) == 'number' then
			result = NVector2(vector.x * object, vector.y * object)
		elseif typeof(object) == 'Vector2' then
			result = NVector2(vector.x * object.X, vector.y * object.Y)
		end

		return assert(result, operr'mul')
	end
	local function divNVector2(vector: NVector2, object: any)
		local result
		
		if typeofnvector2(object) then
			result = NVector2(vector.x / object.x, vector.y / object.y)
		elseif typeof(object) == 'number' then
			result = NVector2(vector.x / object, vector.y / object)
		elseif typeof(object) == 'Vector2' then
			result = NVector2(vector.x / object.X, vector.y / object.Y)
		end
		
		return assert(result, operr'div')
	end
	local function idivNVector2(vector: NVector2, object: any)
		local result

		if typeofnvector2(object) then
			result = NVector2(vector.x // object.x, vector.y // object.y)
		elseif typeof(object) == 'number' then
			result = NVector2(vector.x // object, vector.y // object)
		elseif typeof(object) == 'Vector2' then
			result = NVector2(vector.x // object.X, vector.y // object.Y)
		end

		return assert(result, operr'idiv')
	end
	
	local function tostringNVector2(vector: NVector2)
		return `{vector.x}, {vector.y}`
	end
	
	function new.toVector2()
		return Vector2.new(new.x, new.y)
	end
	
	local newMetatable: metatable.object = {}
	do
		newMetatable.__add      = sumNVector2
		newMetatable.__sub      = subNVector2
		newMetatable.__mul      = mulNVector2
		newMetatable.__div      = divNVector2
		newMetatable.__idiv     = idivNVector2
		newMetatable.__tostring = tostringNVector2
	end
	
	new = setmetatable(new, newMetatable)
	
	return new
end

shared.NVector2Constructor = NVector2

return NVector2
