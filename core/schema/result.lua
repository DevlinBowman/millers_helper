-- core/schema/result.lua

---@class SchemaResult
---@field private __data table
local SchemaResult = {}
SchemaResult.__index = SchemaResult

function SchemaResult.new(data)
    return setmetatable({ __data = data or {} }, SchemaResult)
end

------------------------------------------------
-- value
------------------------------------------------

function SchemaResult:value()
    return self.__data.value
end

------------------------------------------------
-- values
------------------------------------------------

function SchemaResult:values()
    return self.__data.values
end

------------------------------------------------
-- field
------------------------------------------------

function SchemaResult:field()
    return self.__data.field
end

------------------------------------------------
-- template
------------------------------------------------

function SchemaResult:template()
    return self.__data.template
end

------------------------------------------------
-- dto
------------------------------------------------

function SchemaResult:dto()
    return self.__data.dto
end

------------------------------------------------
-- audit
------------------------------------------------

function SchemaResult:audit()
    return self.__data.audit
end

return SchemaResult
