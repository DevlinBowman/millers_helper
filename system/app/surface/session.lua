local Persistence = require("system.app.persistence")

local Session = {}
Session.__index = Session

function Session.new(surface)
    local self = setmetatable({}, Session)
    self._surface = surface
    return self
end

------------------------------------------------------------
-- Reset whole session (context + resources + results)
------------------------------------------------------------

function Session:reset(opts)
    opts = opts or {}

    local state = self._surface.state

    local preserved = {}
    if type(opts.preserve_context_keys) == "table" then
        for _, key in ipairs(opts.preserve_context_keys) do
            preserved[key] = state:get_context(key)
        end
    end

    state:reset()

    for key, value in pairs(preserved) do
        state:set_context(key, value)
    end

    self._surface.hub._cache = {}

    return { ok = true }
end

------------------------------------------------------------
-- Clear only ephemeral results
------------------------------------------------------------

function Session:clear_results()
    self._surface.state:clear_results()
    return { ok = true }
end

------------------------------------------------------------
-- Clear only persisted runtime specs
------------------------------------------------------------

function Session:clear_resources()
    self._surface.state:clear_resources()
    self._surface.hub._cache = {}
    return { ok = true }
end

------------------------------------------------------------
-- Set active ledger
------------------------------------------------------------

function Session:set_active_ledger(ledger_id)
    if type(ledger_id) ~= "string" or ledger_id == "" then
        return { ok = false, error = "ledger_id required" }
    end

    local ok, err = self._surface.state:set_context("active_ledger", ledger_id)
    if not ok then
        return { ok = false, error = err }
    end

    return { ok = true }
end

------------------------------------------------------------
-- Save session
------------------------------------------------------------

function Session:save(opts)
    local ok, err = Persistence.save(self._surface.state, opts)
    if not ok then
        return { ok = false, error = err }
    end
    return { ok = true }
end

------------------------------------------------------------
-- Load session (replace state + rebind hub)
------------------------------------------------------------

function Session:load(opts)
    opts = opts or {}

    local loaded = Persistence.load({ file = opts.file })

    if not loaded then
        return { ok = false, error = "failed to load session" }
    end

    self._surface.state = loaded
    self._surface.hub._specs = loaded.resources
    self._surface.hub._cache = {}

    return { ok = true }
end

return Session
