-- system/app/run.lua

local Storage   = require("system.infrastructure.storage.controller")
local Bootstrap = require("system.infrastructure.bootstrap.controller")
local Persistence = require("system.app.persistence")
local RuntimeHub  = require("system.app.runtime_hub")

local Run = {}

function Run.start(opts)

    opts = opts or {}

    ------------------------------------------------------------
    -- 1. Select Instance (MUST happen first)
    ------------------------------------------------------------

    Storage.set_instance(opts.instance or "default")

    ------------------------------------------------------------
    -- 2. Bootstrap Filesystem
    ------------------------------------------------------------

    Bootstrap.build({
        ledger_id = opts.ledger_id or "default"
    })

    ------------------------------------------------------------
    -- 3. Load Session State
    ------------------------------------------------------------

    local state = Persistence.load()

    ------------------------------------------------------------
    -- 4. Create Runtime Hub
    ------------------------------------------------------------

    local hub = RuntimeHub.new(state.loadables)

    return {
        state = state,
        hub   = hub,
    }
end

return Run
