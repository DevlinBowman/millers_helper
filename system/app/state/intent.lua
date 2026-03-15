-- system/app/state/intent.lua

local Presets = require("system.infrastructure.app_fs.presets")

---@class AppDataIntent
---@field private __intent table
local Intent = {}
Intent.__index = Intent

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param intent_state table
---@return AppDataIntent
function Intent.new(intent_state)

    assert(type(intent_state) == "table", "[data.intent] intent_state required")

    return setmetatable({
        __intent = intent_state
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

    self.__intent[key] = value
end

------------------------------------------------------------

---@param key string
---@return any
function Intent:get(key)

    assert(type(key) == "string" and key ~= "",
        "[data.intent] key required")

    return self.__intent[key]
end

------------------------------------------------------------

---@return table
function Intent:all()
    return self.__intent
end

------------------------------------------------------------

---@param key string
function Intent:clear(key)

    assert(type(key) == "string" and key ~= "",
        "[data.intent] key required")

    self.__intent[key] = nil
end

------------------------------------------------------------

---@return table
function Intent:inspect()
    return self.__intent
end

------------------------------------------------------------
-- Preset Loading
------------------------------------------------------------

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

------------------------------------------------------------

function Intent:write(name, preset)

    assert(type(name) == "string" and name ~= "",
        "[data.intent] preset name required")

    assert(type(preset) == "table",
        "[data.intent] preset table required")

    local path =
        Presets.write("intent", name, preset)

    -- register immediately
    self.__intent[name] = preset

    return path
end

------------------------------------------------------------

function Intent:save(name)

    assert(type(name) == "string" and name ~= "",
        "[data.intent] preset name required")

    local intent = self.__intent[name]

    assert(type(intent) == "table",
        "[data.intent] no intent found for key: " .. name)

    return Presets.write("intent", name, intent)
end

------------------------------------------------------------

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
