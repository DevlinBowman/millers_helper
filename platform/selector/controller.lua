-- platform/selector/controller.lua
--
-- Selector façade.
-- Provides chainable, safe structural traversal over dynamic tables.
--
-- Does NOT return envelopes.
-- Stores traversal state internally.
-- Exposes explicit value and type getters.

local Pipeline   = require("platform.selector.pipelines.resolve")
local Contract   = require("core.contract")
local Trace      = require("tools.trace.trace")

local Controller = {}

----------------------------------------------------------------
-- SelectorView
----------------------------------------------------------------

---@class SelectorView
---@field private __root any        -- original root value
---@field private __value any       -- current resolved value
---@field private __error table|nil -- last traversal failure
local SelectorView = {}
SelectorView.__index = SelectorView

----------------------------------------------------------------
-- CONSTRUCTOR
----------------------------------------------------------------

--- Creates a new SelectorView rooted at the given value.
---
---@param root any
---@return SelectorView
function SelectorView.new(root)
    return setmetatable({
        __root  = root,
        __value = root,
        __error = nil,
    }, SelectorView)
end

----------------------------------------------------------------
-- PATH NAVIGATION
----------------------------------------------------------------

--- Traverses into the current value using the provided keys.
---
--- Each argument may be a string (table key) or number (array index).
--- If traversal fails, the selector enters a failed state.
---
---@param ... string|number
---@return SelectorView
function SelectorView:path(...)
    if self.__error then
        return self
    end

    Trace.contract_enter("selector.path")

    local value, failure = Pipeline.get(self.__value, {...})

    if value == nil then
        self.__error = failure
        self.__value = nil
    else
        self.__value = value
    end

    Trace.contract_leave()
    return self
end

----------------------------------------------------------------
-- INTROSPECTION
----------------------------------------------------------------

--- Returns true if the current selector value is non-nil.
---
---@return boolean
function SelectorView:exists()
    return self.__value ~= nil
end

--- Returns the current resolved value.
--- Returns nil if traversal failed or value is nil.
---
---@return any|nil
function SelectorView:value()
    return self.__value
end

--- Returns the current resolved value.
--- Throws an error if traversal failed or value is nil.
---
---@return any
function SelectorView:require()
    if self.__value == nil then
        error(
            Controller.format_error(self.__error, { label = "selector" }),
            2
        )
    end

    return self.__value
end

----------------------------------------------------------------
-- TYPE GETTERS
----------------------------------------------------------------

--- Returns the value if it is a string.
--- Otherwise returns nil.
---
---@return string|nil
function SelectorView:as_string()
    if type(self.__value) == "string" then
        return self.__value
    end
    return nil
end

--- Returns the value if it is a number.
--- Otherwise returns nil.
---
---@return number|nil
function SelectorView:as_number()
    if type(self.__value) == "number" then
        return self.__value
    end
    return nil
end

--- Returns the value if it is a table.
--- Otherwise returns nil.
---
---@return table|nil
function SelectorView:as_table()
    if type(self.__value) == "table" then
        return self.__value
    end
    return nil
end

--- Returns the value if it is a table.
--- If not a table, returns an empty array.
---
---@return table
function SelectorView:as_array()
    if type(self.__value) ~= "table" then
        return {}
    end
    return self.__value
end

----------------------------------------------------------------
-- ENTRYPOINT
----------------------------------------------------------------

--- Creates a new selector rooted at the provided value.
---
---@param root any
---@return SelectorView
function Controller.from(root)
    Contract.assert({ root = root }, { root = true })
    return SelectorView.new(root)
end

----------------------------------------------------------------
-- ERROR FORMATTER
----------------------------------------------------------------

--- Formats a structured selector failure into a readable message.
---
---@param failure table
---@param opts table|nil
---@return string
function Controller.format_error(failure, opts)
    return require("platform.selector.registry")
        .format_error.run(failure, opts)
end

return Controller
