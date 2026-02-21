-- system/app/persistence.lua
--
-- Persistence for backend state.
-- Uses FileGateway exclusively.
--
-- Persists:
--   • state.context
--   • state.resources
--
-- Never persists:
--   • runtime objects
--   • cached results
--   • transient flags

local FileGateway = require("system.infrastructure.file_gateway")
local State       = require("system.app.state")

local Persistence = {}

Storage.session_file(...)

------------------------------------------------------------
-- load()
------------------------------------------------------------

function Persistence.load(opts)
    opts = opts or {}
    local path = opts.file or DEFAULT_FILE

    local data, err = FileGateway.read_json(path)

    if not data or type(data) ~= "table" then
        return State.new()
    end

    return State.new({
        context   = data.context,
        resources = data.resources,
    })
end

------------------------------------------------------------
-- save()
------------------------------------------------------------

function Persistence.save(state, opts)
    opts = opts or {}
    local path = opts.file or DEFAULT_FILE

    local payload = {
        version   = 1,
        context   = state.context,
        resources = state.resources,
    }

    local meta, err = FileGateway.write_json(path, payload)

    if not meta then
        return false, err
    end

    return true
end

return Persistence
