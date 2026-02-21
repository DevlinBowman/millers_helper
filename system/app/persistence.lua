-- system/app/persistence.lua

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")
local State       = require("system.app.state")

local Persistence = {}

------------------------------------------------------------
-- load()
------------------------------------------------------------

function Persistence.load(opts)

    opts = opts or {}

    local path = opts.file or Storage.session_file("last_session")

    local data = FileGateway.read_json(path)

    if not data or type(data) ~= "table" then
        return State.new()
    end

    return State.new({
        context   = data.context,
        loadables = data.loadables,
        results   = {},
    })
end

------------------------------------------------------------
-- save()
------------------------------------------------------------

function Persistence.save(state, opts)

    opts = opts or {}

    local path = opts.file or Storage.session_file("last_session")

    local payload = {
        version   = 1,
        context   = state.context,
        loadables = state.loadables,
    }

    local ok, err = FileGateway.write_json(path, payload)

    if not ok then
        return false, err
    end

    return true
end

return Persistence
