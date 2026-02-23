-- system/backend.lua

local Storage        = require("system.infrastructure.storage.controller")
local Bootstrap      = require("system.infrastructure.bootstrap.controller")
local Surface        = require("system.app.surface")
local SystemDefaults = require("system.app.system_defaults")

local Backend = {}

function Backend.start(opts)
    opts = opts or {}

    local instance  = opts.instance  or "default"
    local ledger_id = opts.ledger_id or "default"

    Storage.set_instance(instance)

    Bootstrap.build({
        ledger_id = ledger_id
    })

    local surface = Surface.new(opts)

    -- Canonicalize active ledger context
    if surface and surface.state and surface.state.set_context then
        surface.state:set_context("active_ledger", ledger_id)
    end

    -- Apply system-owned default resources (canonical reference store)
    SystemDefaults.apply(surface)
    print("STATE TABLE:", surface.state.resources)
print("HUB TABLE:", surface.hub._specs)
print("SAME TABLE?", surface.state.resources == surface.hub._specs)

    return surface
end

return Backend
