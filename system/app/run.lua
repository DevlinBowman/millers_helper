-- system/app/run.lua
--
-- System Bootstrap Entrypoint (Non-Surface Path)
--
-- Responsibility:
--   • Initialize storage instance
--   • Ensure filesystem layout exists
--   • Load persisted session state
--   • Construct RuntimeHub
--
-- This module provides a low-level startup path for:
--   • CLI runners
--   • Test harnesses
--   • Non-Surface entrypoints
--
-- It intentionally does NOT:
--   • Construct a Surface
--   • Execute services
--   • Perform domain logic
--
-- Ordering is critical:
--   1. Storage instance must be set first
--   2. Filesystem must be bootstrapped before load
--   3. State must be loaded before RuntimeHub is created

local Storage     = require("system.infrastructure.storage.controller")
local Bootstrap   = require("system.infrastructure.bootstrap.controller")
local Persistence = require("system.app.persistence")
local RuntimeHub  = require("system.app.runtime_hub")

---@class Run
local Run = {}

----------------------------------------------------------------
-- start()
----------------------------------------------------------------
-- Bootstraps the application runtime environment.
--
-- Flow:
--   1. Select instance (affects all Storage paths)
--   2. Ensure required directories/files exist
--   3. Load persisted session state
--   4. Create runtime hub bound to state.resources
--
-- Returns raw components instead of Surface.
--
---@param opts? { instance?: string, ledger_id?: string }
---@return { state: State, hub: RuntimeHub }
function Run.start(opts)

    opts = opts or {}

    ------------------------------------------------------------
    -- 1. Select Instance (MUST happen first)
    --
    -- Storage paths depend on the active instance.
    -- All filesystem operations resolve through Storage.
    ------------------------------------------------------------

    Storage.set_instance(opts.instance or "default")

    ------------------------------------------------------------
    -- 2. Bootstrap Filesystem
    --
    -- Ensures:
    --   • ledger root exists
    --   • session file exists
    --   • required system directories exist
    --
    -- Safe to call repeatedly (idempotent).
    ------------------------------------------------------------

    Bootstrap.build({
        ledger_id = opts.ledger_id or "default"
    })

    ------------------------------------------------------------
    -- 3. Load Session State
    --
    -- Loads:
    --   • context
    --   • resource specifications
    --
    -- Does NOT load runtime objects.
    ------------------------------------------------------------

    local state = Persistence.load()

    ------------------------------------------------------------
    -- 4. Create Runtime Hub
    --
    -- RuntimeHub receives a direct reference to state.resources.
    -- This allows:
    --   • Spec mutation through State
    --   • Lazy runtime construction
    --   • Ephemeral caching
    ------------------------------------------------------------

    local hub = RuntimeHub.new(state.resources)

    return {
        state = state,
        hub   = hub,
    }
end

return Run
