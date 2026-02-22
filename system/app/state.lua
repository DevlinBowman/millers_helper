-- system/app/state.lua
--
-- Minimal persistent state container.
-- Owns ONLY persistable session data.
-- No domain logic.
-- No IO.
-- No runtime objects.

local State = {}
State.__index = State

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function ensure_table(value)
    if type(value) == "table" then
        return value
    end
    return {}
end

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function State.new(initial)
    initial = ensure_table(initial)

    local self = setmetatable({}, State)

    -- Persisted data
    self.context   = ensure_table(initial.context)
    self.resources = ensure_table(initial.resources)

    -- Ephemeral (never persisted)
    self.results   = ensure_table(initial.results)

    return self
end

----------------------------------------------------------------
-- Resource Management (Persisted Runtime Specs)
----------------------------------------------------------------
-- A resource is a persistable runtime specification:
--
-- resources[name] = {
--     input = <path|string|table>,
--     opts  = <table>
-- }

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

function State:get_resource(name)
    if type(name) ~= "string" then
        return nil
    end
    return self.resources[name]
end

function State:clear_resource(name)
    if type(name) ~= "string" then
        return false, "invalid resource name"
    end

    self.resources[name] = nil
    return true
end

function State:resources_table()
    return self.resources
end

----------------------------------------------------------------
-- Context (Persisted)
----------------------------------------------------------------

function State:set_context(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "invalid context key"
    end

    self.context[key] = value
    return true
end

function State:get_context(key)
    if type(key) ~= "string" then
        return nil
    end

    return self.context[key]
end

function State:context_table()
    return self.context
end

----------------------------------------------------------------
-- Results (Ephemeral)
----------------------------------------------------------------

function State:set_result(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "invalid result key"
    end

    self.results[key] = value
    return true
end

function State:get_result(key)
    if type(key) ~= "string" then
        return nil
    end

    return self.results[key]
end

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

function State:to_persistable()
    return {
        version   = 1,
        context   = self.context,
        resources = self.resources,
    }
end

return State
