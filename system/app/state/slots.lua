-- system/app/state/slots.lua

---@class AppDataSlots
---@field private __state table
local Slots = {}
Slots.__index = Slots

---@param state table
---@return AppDataSlots
function Slots.new(state)

    state.slots = state.slots or {}

    state.slots.selection = state.slots.selection or {
        user   = {},
        system = {},
    }

    state.slots.config = state.slots.config or {}

    return setmetatable({
        __state = state
    }, Slots)
end

------------------------------------------------------------
-- Selection (single value per scope+role)
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param value number|string
function Slots:set_selection(scope, role, value)
    assert(scope == "system" or scope == "user",
        "[slots] invalid scope")
    assert(type(role) == "string" and role ~= "",
        "[slots] role required")
    assert(type(value) == "number" or type(value) == "string",
        "[slots] selection must be number (index) or string (id)")

    self.__state.slots.selection[scope][role] = value
end

---@param scope "system"|"user"
---@param role string
---@return number|string|nil
function Slots:get_selection(scope, role)
    return self.__state.slots.selection[scope][role]
end

---@param scope "system"|"user"
---@param role string
function Slots:clear_selection(scope, role)
    self.__state.slots.selection[scope][role] = nil
end

------------------------------------------------------------
-- Config (simple key-value)
------------------------------------------------------------

---@param key string
---@param value any
function Slots:set_config(key, value)
    assert(type(key) == "string" and key ~= "",
        "[slots] config key required")
    self.__state.slots.config[key] = value
end

---@param key string
---@return any
function Slots:get_config(key)
    return self.__state.slots.config[key]
end

return Slots
