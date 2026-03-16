-- system/app/facade/data.lua
--
-- Canonical application data container
--
-- app
--  └ data
--      ├ vars
--      ├ inputs
--      ├ resources
--      ├ runtime
--      ├ slots
--      ├ intent
--      └ ctx

local Vars      = require("system.app.state.vars")
local Input     = require("system.app.state.input")
local Resources = require("system.app.state.resources")
local RuntimeNS = require("system.app.state.runtime")
local Session   = require("system.app.state.session")
local Slots     = require("system.app.state.slots")
local Intent    = require("system.app.state.intent")
local Context   = require("system.app.state.context")

---@class AppDataFacade
---@field vars fun(self:AppDataFacade):AppDataVars
---@field input fun(self:AppDataFacade):AppDataInput
---@field resources fun(self:AppDataFacade):AppDataResources
---@field runtime fun(self:AppDataFacade):AppDataRuntime
---@field slots fun(self:AppDataFacade):AppDataSlots
---@field intent fun(self:AppDataFacade):AppDataIntent
---@field context fun(self:AppDataFacade):AppDataContext
---@field session fun(self:AppDataFacade):AppDataSession
local Data = {}
Data.__index = Data

------------------------------------------------------------
-- Initial State
------------------------------------------------------------

local function build_initial_state()

    return {

        vars = {},

        inputs = {
            by_role = {}
        },

        resources = {
            user   = {},
            system = {}
        },

        runtime = {
            user   = {},
            system = {}
        },

        slots = {
            config = {},
            selection = {
                user   = {},
                system = {}
            }
        },

        intent = {},

        ctx = {
            active = nil,
            store  = {}
        }
    }
end

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

function Data.new(app)

    local instance = setmetatable({

        __app       = app,
        __state     = build_initial_state(),

        __vars      = nil,
        __input     = nil,
        __resources = nil,
        __runtime   = nil,
        __session   = nil,
        __slots     = nil,
        __intent    = nil,
        __context   = nil,

    }, Data)

    return instance
end

------------------------------------------------------------
-- Vars
------------------------------------------------------------

function Data:vars()

    if not self.__vars then
        self.__vars = Vars.new(self.__state.vars)
    end

    return self.__vars
end

------------------------------------------------------------
-- Inputs
------------------------------------------------------------

function Data:input()

    if not self.__input then
        self.__input = Input.new(self.__state.inputs)
    end

    return self.__input
end

------------------------------------------------------------
-- Resources
------------------------------------------------------------

function Data:resources()

    if not self.__resources then

        local function read_inputs()
            return self.__state.inputs.by_role
        end

        self.__resources =
            Resources.new(
                self.__app,
                self.__state.resources,
                read_inputs
            )

        self.__resources:pull_system()
        self.__resources:pull_user_from_inputs()
    end

    return self.__resources
end

------------------------------------------------------------
-- Runtime
------------------------------------------------------------

function Data:runtime()

    if not self.__runtime then
        self.__runtime =
            RuntimeNS.new(
                self.__state.runtime,
                self:resources()
            )
    end

    return self.__runtime
end

------------------------------------------------------------
-- Slots
------------------------------------------------------------

function Data:slots()

    if not self.__slots then
        self.__slots = Slots.new(self.__state.slots)
    end

    return self.__slots
end

------------------------------------------------------------
-- Intent
------------------------------------------------------------

function Data:intent()

    if not self.__intent then
        self.__intent = Intent.new(self.__state.intent)
    end

    return self.__intent
end

------------------------------------------------------------
-- Context
------------------------------------------------------------

function Data:context()

    if not self.__context then
        self.__context = Context.new(self.__state.ctx)
    end

    return self.__context
end

------------------------------------------------------------
-- Session
------------------------------------------------------------

function Data:session()

    if not self.__session then
        self.__session = Session.new(self.__state.vars)
    end

    return self.__session
end

------------------------------------------------------------
-- Submit Inputs
------------------------------------------------------------

function Data:submit(role, payload)

    local input_descriptor =
        self:input():set(role, payload)

    local resource_status =
        self:resources():pull_user_from_inputs()

    if self.__runtime then
        self.__runtime:clear_role("user", role)
    end

    return {
        ok = true,
        role = role,
        input = input_descriptor,
        resource_status = resource_status.status
    }
end

------------------------------------------------------------
-- Raw State Access
------------------------------------------------------------

function Data:state()
    return self.__state
end

------------------------------------------------------------
-- Clean Inspection
------------------------------------------------------------

function Data:inspect()

    return {
        vars      = self.__state.vars,
        inputs    = self.__state.inputs.by_role,
        resources = self.__state.resources,
        runtime   = self.__state.runtime,
        slots     = self.__state.slots,
        intent    = self.__state.intent,
        ctx       = self.__state.ctx
    }
end

return Data
