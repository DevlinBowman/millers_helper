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
local Intent    = require("system.app.state.intent")
local Context   = require("system.app.state.context")

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
        intent = {},
        inputs = { by_role = {} },
        resources = {
            user   = {},
            system = {}
        },
        runtime = {
            user   = {},
            system = {},
        },
        ------------------------------------------------
        -- transient execution contexts
        ------------------------------------------------
        ctx = {
            active = nil,
            store  = {}
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
        __intent    = nil,
        __input     = nil,
        __resources = nil,
        __runtime   = nil,
        __session   = nil,
        __context   = nil,

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

        local function read_inputs()
            local inputs = self.__state.inputs
            return inputs and inputs.by_role or {}
        end

        self.__resources =
            Resources.new(
                self.__app,
                self.__state.resources,
                read_inputs
            )

        ------------------------------------------------------------
        -- Initialize resource descriptors
        ------------------------------------------------------------

        self.__resources:pull_system()
        self.__resources:pull_user_from_inputs()
    end

    return self.__resources
end

---@return AppDataRuntime
function Data:runtime()

    if not self.__runtime then

        local resources = self:resources()

        local function read_resources()
            return {
                system = resources:system(),
                user   = resources:user(),
            }
        end

        ---@param scope "system"|"user"
        ---@param role string
        ---@param index integer
        ---@return any
        local function loader(scope, role, index)

            local list = resources:get(scope, role)

            list = assert(list,
                "[data.runtime] missing resource list: "
                .. tostring(scope) .. "." .. tostring(role))

            local entry = list[index]

            entry = assert(entry,
                "[data.runtime] missing resource entry: "
                .. tostring(scope) .. "." .. tostring(role)
                .. "[" .. tostring(index) .. "]")

            return resources:load_entry(entry)
        end

        ---@param scope "system"|"user"
        ---@param role string
        ---@param id string
        ---@return integer|nil
        local function resolve_index(scope, role, id)

            local list = resources:get(scope, role)

            if not list then
                return nil
            end

            for i = 1, #list do
                if list[i].id == id then
                    return i
                end
            end

            return nil
        end

        self.__runtime =
            RuntimeNS.new(
                self.__state,
                loader,
                resolve_index,
                read_resources
            )
    end

    return self.__runtime
end

---@return AppDataSession
function Data:session()

    if not self.__session then
        self.__session = Session.new(self.__state.vars)
    end

    return self.__session
end


---@return AppDataVars
function Data:vars()

    if not self.__vars then
        self.__vars = Vars.new(self.__state.vars)
    end

    return self.__vars
end


---@return table
function Data:state()
    return self.__state
end


---@return AppDataSlots
function Data:slots()

    if not self.__slots then
        self.__slots = Slots.new(self.__state.slots)
    end

    return self.__slots
end


---@return AppDataIntent
function Data:intent()

    if not self.__intent then
        self.__intent = Intent.new(self.__state.intent)
    end

    return self.__intent
end


---Submit external input into system and promote to resources.
---@param role string
---@param payload table
---@return table
function Data:submit(role, payload)

    local descriptor =
        self:input():set(role, payload)

    local result =
        self:resources():pull_user_from_inputs()

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
        intent    = self.__state.intent,
        inputs    = self.__state.inputs.by_role,
        resources = self.__state.resources,
        runtime   = self.__state.runtime,
        slots     = self.__state.slots,
        ctx       = self.__state.ctx
    }

end


---@return AppDataContext
function Data:context()

    if not self.__context then
        self.__context = Context.new(self.__state.ctx)
    end

    return self.__context
end

return Data
