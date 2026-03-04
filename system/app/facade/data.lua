-- system/app/data.lua
--
---@class AppDataSession
---@class AppDataVars
---@class AppDataInput
---@class AppDataResources
---@class AppDataRuntime

local Vars      = require("system.app.state.vars")
local Input     = require("system.app.state.input")
local Resources = require("system.app.state.resources")
local RuntimeNS = require("system.app.state.runtime")
local Session   = require("system.app.state.session")
local Slots     = require("system.app.state.slots")

---@class AppDataFacade
---@field private __app Surface
---@field private __state table
---@field private __vars AppDataVars|nil
---@field private __input AppDataInput|nil
---@field private __resources AppDataResources|nil
---@field private __runtime AppDataRuntime|nil
---@field private __session AppDataSession|nil
---@field private __slots AppDataSlots|nil
local Data      = {}
Data.__index    = Data

------------------------------------------------------------
-- Constructor
------------------------------------------------------------
---
local function build_initial_state()
    return {
        vars = {},
        slots = {},
        inputs = { by_role = {} },
        resources = {
            user   = {},
            system = {}
        },
        runtime = {
            user   = {},
            system = {},
        }
    }
end

---@param app Surface
---@return AppDataFacade
function Data.new(app)
    ---@type AppDataFacade
    local instance = setmetatable({
        __app       = app,

        __state     = build_initial_state(),

        __vars      = nil,
        __slots     = nil,
        __input     = nil,
        __resources = nil,
        __runtime   = nil,
        __session   = nil,
    }, Data)

    return instance
end

------------------------------------------------------------
-- Facade Accessors
------------------------------------------------------------

---@return AppDataInput
function Data:input()
    if not self.__input then
        self.__input = Input.new(self.__state)
    end
    return self.__input
end

---@return AppDataResources
function Data:resources()
    if not self.__resources then
        self.__resources = Resources.new(self.__app, self.__state)
    end
    return self.__resources
end

---@return AppDataRuntime
function Data:runtime()
    if not self.__runtime then
        local resources = self:resources()

        ---@param scope "system"|"user"
        ---@param role string
        ---@param index integer
        ---@return any
        local function loader(scope, role, index)
            local list = resources:get(scope, role)
            list = assert(list, "[data.runtime] missing resource list: " .. tostring(scope) .. "." .. tostring(role))

            local entry = list[index]
            entry = assert(entry,
                "[data.runtime] missing resource entry: " ..
                tostring(scope) .. "." .. tostring(role) .. "[" .. tostring(index) .. "]")

            return resources:load_entry(entry)
        end

        ---@param scope "system"|"user"
        ---@param role string
        ---@param id string
        ---@return integer|nil
        local function resolve_index(scope, role, id)
            local list = resources:get(scope, role)
            if type(list) ~= "table" then
                return nil
            end

            for i = 1, #list do
                local entry = list[i]
                if type(entry) == "table" and entry.id == id then
                    return i
                end
            end

            return nil
        end

        self.__runtime = RuntimeNS.new(self.__state, loader, resolve_index)
    end

    return self.__runtime
end

---@return AppDataSession
function Data:session()
    if not self.__session then
        self.__session = Session.new(self.__state)
    end
    return self.__session
end

---@return AppDataVars
function Data:vars()
    if not self.__vars then
        self.__vars = Vars.new(self.__state)
    end
    return self.__vars
end

---@return AppDataSlots
function Data:slots()
    if not self.__slots then
        self.__slots = Slots.new(self.__state)
    end
    return self.__slots
end

---Submit external input into system and promote to resources.
---@param role string
---@param payload table
---@return table
function Data:submit(role, payload)
    -- 1. register input
    local descriptor = self:input():set(role, payload)

    -- 2. rebuild user resources from current inputs
    local result = self:resources():pull_user_from_inputs()

    return {
        ok = true,
        role = role,
        input = descriptor,
        resource_status = result.status
    }
end

------------------------------------------------------------
-- Inspection
------------------------------------------------------------

---@return table
function Data:inspect()
    return {
        vars      = self.__state.vars,
        inputs    = self.__state.inputs.by_role,
        resources = self.__state.resources,
        runtime   = self.__state.runtime,
        slots     = self.__state.slots
    }
end

return Data
