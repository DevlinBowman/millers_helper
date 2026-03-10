-- system/app/state/intent.lua

---@class AppDataIntent
---@field private __state table
local Intent = {}
Intent.__index = Intent

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param state table
---@return AppDataIntent
function Intent.new(state)

    assert(type(state) == "table", "[data.intent] state required")

    state.intent = state.intent or {}

    return setmetatable({
        __state = state
    }, Intent)
end

------------------------------------------------------------
-- Core API
------------------------------------------------------------

---@param key string
---@param value any
function Intent:set(key, value)
    assert(type(key) == "string" and key ~= "",
        "[data.intent] key required")

    self.__state.intent[key] = value
end

---@param key string
---@return any
function Intent:get(key)
    assert(type(key) == "string" and key ~= "",
        "[data.intent] key required")

    return self.__state.intent[key]
end

---@return table
function Intent:all()
    return self.__state.intent
end

---@param key string
function Intent:clear(key)
    assert(type(key) == "string" and key ~= "",
        "[data.intent] key required")

    self.__state.intent[key] = nil
end

---@return table
function Intent:inspect()
    return self.__state.intent
end

return Intent
