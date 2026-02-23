-- system/backend.lua
--
-- Canonical Backend Entrypoint
--
-- Owns:
--   • Storage instance selection
--   • Filesystem bootstrap
--   • Surface construction
--
-- Returns:
--   Fully initialized Surface object
--
-- This is the only "door" into the backend.

local Storage   = require("system.infrastructure.storage.controller")
local Bootstrap = require("system.infrastructure.bootstrap.controller")
local Surface   = require("system.app.surface")

local Backend = {}

------------------------------------------------------------
-- start(opts)
------------------------------------------------------------
-- Boots backend and returns Surface instance.
--
-- opts:
--   instance:   string (default "default")
--   ledger_id:  string (default "default")
--   persistence: table passed through to Persistence.load via Surface.new(opts)

function Backend.start(opts)
    opts = opts or {}

    local instance  = opts.instance  or "default"
    local ledger_id = opts.ledger_id or "default"

    --------------------------------------------------------
    -- 1. Select Instance
    --------------------------------------------------------

    Storage.set_instance(instance)

    --------------------------------------------------------
    -- 2. Bootstrap Filesystem (idempotent)
    --------------------------------------------------------

    Bootstrap.build({
        ledger_id = ledger_id
    })

    --------------------------------------------------------
    -- 3. Construct Surface (loads state + binds hub)
    --------------------------------------------------------

    local surface = Surface.new(opts)

    --------------------------------------------------------
    -- 4. Canonicalize active ledger context
    --------------------------------------------------------

    if surface and surface.state and surface.state.set_context then
        surface.state:set_context("active_ledger", ledger_id)
    end

    return surface
end

return Backend
