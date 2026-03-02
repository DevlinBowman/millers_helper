---@class AppDataVars
---@field private __state table
local Vars = {}
Vars.__index = Vars

function Vars.new(state)
    return setmetatable({ __state = state }, Vars)
end

function Vars:set(key, value)
    assert(type(key) == "string" and #key > 0, "[data.vars] key required")
    self.__state.vars[key] = value
end

function Vars:get(key)
    return self.__state.vars[key]
end

function Vars:clear(key)
    self.__state.vars[key] = nil
end

function Vars:all()
    return self.__state.vars
end

return Vars
