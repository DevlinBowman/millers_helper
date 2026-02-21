-- system/persistence.lua
--
-- Persistence for backend state.
-- Uses platform.io.controller exclusively.
--
-- Persists:
--   • state.context
--   • state.loadables
--
-- Never persists:
--   • runtime objects
--   • cached results
--   • transient flags

local IO    = require("platform.io.controller")
local State = require("system.app.state")

local Persistence = {}

local DEFAULT_FILE = "data/app/.backend_session.json"

------------------------------------------------------------
-- load()
------------------------------------------------------------

function Persistence.load(opts)
    opts = opts or {}
    local path = opts.file or DEFAULT_FILE

    local result, err = IO.read(path)

    if not result then
        -- file missing or invalid → return fresh state
        return State.new()
    end

    if type(result.data) ~= "table" then
        return State.new()
    end

    return State.new({
        context   = result.data.context,
        loadables = result.data.loadables,
    })
end

------------------------------------------------------------
-- save()
------------------------------------------------------------

function Persistence.save(state, opts)
    opts = opts or {}
    local path = opts.file or DEFAULT_FILE

    local payload = state:to_persistable()

    local meta, err = IO.write(path, payload)

    if not meta then
        return false, err
    end

    return true
end

return Persistence
