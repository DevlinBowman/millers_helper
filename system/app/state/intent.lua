-- system/app/state/intent.lua

local Presets = require("system.infrastructure.app_fs.presets")

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

function Intent:load(name)

    assert(type(name) == "string" and name ~= "",
        "[data.intent] preset name required")

    local preset =
        Presets.read("intent", name)

    assert(type(preset) == "table",
        "[data.intent] preset must decode to table")

    self:set(name, preset)

    return preset
end

function Intent:write(name, preset)

    assert(type(name) == "string" and name ~= "",
        "[data.intent] preset name required")

    assert(type(preset) == "table",
        "[data.intent] preset table required")

    local path =
        Presets.write("intent", name, preset)

    -- immediately register it in current state
    self.__state.intent[name] = preset

    return path
end

function Intent:save(name)

    assert(type(name) == "string" and name ~= "",
        "[data.intent] preset name required")

    local intent = self.__state.intent[name]

    assert(type(intent) == "table",
        "[data.intent] no intent found for key: " .. name)

    return Presets.write("intent", name, intent)
end

function Intent:pull_all()

    local presets =
        Presets.list("intent")

    for _, name in ipairs(presets) do

        local preset =
            Presets.read("intent", name)

        if type(preset) == "table" then
            self:set(name, preset)
        end
    end

    return presets
end

return Intent
