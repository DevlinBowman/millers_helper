-- system/app/state.lua
--
-- State
-- =====
--
-- State is the minimal session container.
--
-- It owns ONLY:
--   • context   (persisted key/value session data)
--   • resources (persisted runtime specifications)
--
-- It also owns:
--   • results   (ephemeral service outputs; never persisted)
--
-- It explicitly does NOT:
--   • Perform IO
--   • Load runtimes
--   • Perform domain logic
--   • Validate business rules
--
-- State is intentionally simple.
-- It models *session intent*, not execution.

---@class State
---@field context table<string, any>                      -- Persisted session context
---@field resources table<string, RuntimeSpec>           -- Persisted runtime specifications
---@field results table<string, any>                     -- Ephemeral service outputs
local State = {}
State.__index = State

----------------------------------------------------------------
-- Types
----------------------------------------------------------------

---@class RuntimeSpec
---@field inputs table      -- Runtime inputs (simple array or labeled table)
---@field opts table        -- Runtime options

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

---@param value any
---@return table
local function ensure_table(value)
    if type(value) == "table" then
        return value
    end
    return {}
end

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param initial? table
---@return State
function State.new(initial)
    initial = ensure_table(initial)

    local self = setmetatable({}, State)

    ------------------------------------------------------------
    -- Persisted data
    ------------------------------------------------------------

    -- Arbitrary session key/value pairs.
    -- Example: active_ledger
    self.context   = ensure_table(initial.context)

    -- Runtime specifications only.
    -- NEVER runtime objects.
    self.resources = ensure_table(initial.resources)

    ------------------------------------------------------------
    -- Ephemeral data
    ------------------------------------------------------------

    -- Service outputs (compare, quote, invoice, etc.)
    -- NEVER persisted.
    self.results   = ensure_table(initial.results)

    return self
end

----------------------------------------------------------------
-- Resource Management (Persisted Runtime Specs)
----------------------------------------------------------------
-- A resource is a persistable runtime specification:
--
-- resources[name] = {
--     inputs = <array|string|labeled-table>,
--     opts   = <table>
-- }
--
-- No validation of inputs occurs here.
-- RuntimeHub is responsible for interpreting these specs.

---@param name string
---@param spec RuntimeSpec
---@return boolean|string
function State:set_resource(name, spec)
    if type(name) ~= "string" or name == "" then
        return false, "invalid resource name"
    end

    if type(spec) ~= "table" then
        return false, "resource spec must be table"
    end

    if spec.inputs == nil then
        return false, "resource spec missing inputs"
    end

    spec.opts = ensure_table(spec.opts)

    self.resources[name] = spec
    return true
end

---@param name string
---@return RuntimeSpec|nil
function State:get_resource(name)
    if type(name) ~= "string" then
        return nil
    end
    return self.resources[name]
end

---@param name string
---@return boolean|string
function State:clear_resource(name)
    if type(name) ~= "string" then
        return false, "invalid resource name"
    end

    self.resources[name] = nil
    return true
end

---@return table<string, RuntimeSpec>
function State:resources_table()
    return self.resources
end

----------------------------------------------------------------
-- Context (Persisted)
----------------------------------------------------------------
-- Arbitrary key/value session data.
-- Example:
--   state:set_context("active_ledger", "default")

---@param key string
---@param value any
---@return boolean|string
function State:set_context(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "invalid context key"
    end

    self.context[key] = value
    return true
end

---@param key string
---@return any
function State:get_context(key)
    if type(key) ~= "string" then
        return nil
    end

    return self.context[key]
end

---@return table<string, any>
function State:context_table()
    return self.context
end

----------------------------------------------------------------
-- Results (Ephemeral)
----------------------------------------------------------------
-- Service outputs are stored here.
-- Examples:
--   state:set_result("compare", model)
--   state:set_result("invoice", model)
--
-- Results are NEVER persisted.

---@param key string
---@param value any
---@return boolean|string
function State:set_result(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "invalid result key"
    end

    self.results[key] = value
    return true
end

---@param key string
---@return any
function State:get_result(key)
    if type(key) ~= "string" then
        return nil
    end

    return self.results[key]
end

---@param key string
---@return boolean|string
function State:clear_result(key)
    if type(key) ~= "string" then
        return false, "invalid result key"
    end

    self.results[key] = nil
    return true
end

----------------------------------------------------------------
-- Persistable Snapshot
----------------------------------------------------------------
-- Produces a serializable snapshot.
-- This is what Persistence.save() writes to disk.
--
-- results intentionally excluded.

---@return { version: number, context: table, resources: table }
function State:to_persistable()
    return {
        version   = 1,
        context   = self.context,
        resources = self.resources,
    }
end

return State
