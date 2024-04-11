--- base types ---
type table = {[any]: any}
type void  = nil

--- reduct ---
type concatOperator = string | number | table
type sumOperator    = number | table

--- util ---
type mathMethod  = (table: table, value: sumOperator) -> number?
type logicMethod = (table: table, value: any?) -> boolean?

type MT = {
	__index:     (table: table, index: any) -> any?,
	__newindex:  (table: table, index: any, value: any) -> void?,
	__call:      (table: table, ...any) -> any?,
	__concat:    (table: table, value: concatOperator) -> string?,
	__unm:       (table: table) -> any?,
	__add:       mathMethod,
	__sub:       mathMethod,
	__mul:       mathMethod,
	__div:       mathMethod,
	__idiv:      mathMethod,
	__mod:       mathMethod,
	__pov:       mathMethod,
	__tostring:  (table: table) -> string?,
	__metatable: any?,
	__eq:        logicMethod,
	__lt:        logicMethod,
	__le:        logicMethod,
	__mode:      string?,
	__gc:        (table: table) -> void?,
	__len:       (table: table) -> number?,
	__iter:      (table: table) -> (table: table, lastKey: any?) -> (any?, any)
}

export type object = MT

return nil
