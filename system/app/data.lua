-- system/app/data.lua
--
---@class AppDataSession
---@class AppDataVars
---@class AppDataInput
---@class AppDataResources
---@class AppDataRuntime

local Vars      = require("system.app.data.vars")
local Input     = require("system.app.data.input")
local Resources = require("system.app.data.resources")
local RuntimeNS = require("system.app.data.runtime")
local Session   = require("system.app.data.session")

---@class AppDataFacade
---@field private __app Surface
---@field private __state table
---@field private __vars AppDataVars|nil
---@field private __input AppDataInput|nil
---@field private __resources AppDataResources|nil
---@field private __runtime AppDataRuntime|nil
---@field private __session AppDataSession|nil
local Data = {}
Data.__index = Data

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppDataFacade
function Data.new(app)
    ---@type AppDataFacade
    local instance = setmetatable({
        __app = app,

        __state = {
            vars = {},
            inputs = { by_role = {} },
            resources = {
                user   = {},
                system = {}
            },
            runtime = {
                user   = {},
                system = {},
            }
        },

        __vars      = nil,
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
        ---@param identifier string
        ---@return any
        local function loader(scope, role, identifier)
            local entry = resources:get(scope, role, identifier)
            entry = assert(
                entry,
                "[data.runtime] missing resource: "
                    .. tostring(scope) .. "."
                    .. tostring(role) .. "."
                    .. tostring(identifier)
            )
            return resources:load_entry(entry)
        end

        self.__runtime = RuntimeNS.new(self.__state, loader)
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

------------------------------------------------------------
-- Inspection
------------------------------------------------------------

---@return table
function Data:inspect()
    return {
        vars      = self.__state.vars,
        inputs    = self.__state.inputs.by_role,
        resources = self.__state.resources,
        runtime   = self.__state.runtime
    }
end

return Data
