-- system/app/surface.lua
--
-- Surface is the **application boundary object**.
--
-- It is the ONLY object in the system that is allowed to:
--   • Own persisted State
--   • Own a RuntimeHub (ephemeral runtime layer)
--   • Orchestrate services
--
-- It is NOT allowed to:
--   • Load runtime objects directly
--   • Perform domain logic
--   • Perform filesystem IO directly
--
-- Think of Surface as:
--   "Session-level façade over state + runtime + services"

local Persistence = require("system.app.persistence")
local RuntimeHub  = require("system.app.runtime_hub")

local CompareSvc  = require("system.services.compare_service")
local QuoteSvc    = require("system.services.quote_service")
local InvoiceSvc  = require("system.services.invoice_service")
local IngestSvc   = require("system.services.ingest_service")

---@class Surface
---@field state State                 -- Persisted + ephemeral session state
---@field hub RuntimeHub              -- Ephemeral runtime resolver (lazy)
local Surface = {}
Surface.__index = Surface

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param opts? table
---@return Surface
function Surface.new(opts)
    opts = opts or {}

    -- Load persisted session state (context + resource specs)
    local state = Persistence.load(opts.persistence)

    local self = setmetatable({}, Surface)

    self.state = state

    -- CRITICAL:
    -- RuntimeHub is bound directly to state.resources.
    -- This means specs mutate in-place and are immediately visible.
    self.hub = RuntimeHub.new(self.state.resources)

    return self
end

----------------------------------------------------------------
-- Resource Management (Persisted Specs)
----------------------------------------------------------------
-- A "resource" is NOT a runtime.
-- It is a persistable runtime specification:
--
--   resources[name] = {
--       inputs = { ... },
--       opts   = { ... }
--   }
--
-- RuntimeHub resolves these lazily.

---@param name string
---@param input string|table
---@param opts? table
---@return boolean|string
function Surface:set_resource(name, input, opts)

    local inputs

    if type(input) == "table" then
        inputs = input
    else
        inputs = { input }
    end

    return self.state:set_resource(name, {
        inputs = inputs,
        opts   = opts or {}
    })
end

---@param name string
---@return table|nil
function Surface:get_resource(name)
    return self.state:get_resource(name)
end

---@param name string
---@return boolean|string
function Surface:clear_resource(name)
    return self.state:clear_resource(name)
end

----------------------------------------------------------------
-- Services
----------------------------------------------------------------
-- Services are pure orchestration units.
-- They:
--   • Resolve runtimes via hub
--   • Call domain controllers
--   • Store ephemeral results in state.results

---@param opts? table
---@return table
function Surface:run_compare(opts)
    return CompareSvc.handle({
        state = self.state,
        hub   = self.hub,
        opts  = opts
    })
end

---@param opts? table
---@return table
function Surface:run_quote(opts)
    return QuoteSvc.handle({
        state = self.state,
        hub   = self.hub,
        opts  = opts
    })
end

---@param opts? table
---@return table
function Surface:run_invoice(opts)
    return InvoiceSvc.handle({
        state = self.state,
        hub   = self.hub,
        opts  = opts
    })
end

---@param opts table
---@return table
function Surface:run_ingest(opts)
    -- Ingest is intentionally standalone and does not require state/hub.
    return IngestSvc.handle(opts)
end

----------------------------------------------------------------
-- Persistence
----------------------------------------------------------------

---@param opts? table
---@return boolean|string
function Surface:save(opts)
    return Persistence.save(self.state, opts)
end

---@return State
function Surface:get_state()
    return self.state
end

----------------------------------------------------------------
-- Status (Runtime Introspection)
----------------------------------------------------------------
-- Provides a structured snapshot for UI.
-- Does NOT mutate anything.

---@return table
function Surface:status()

    local hub   = self.hub
    local state = self.state

    local out = {}

    ------------------------------------------------------------
    -- USER RESOURCE
    ------------------------------------------------------------

    do
        local configured = hub:is_configured("user")
        local loaded     = hub:is_loaded("user")

        local batches = 0

        if loaded then
            local runtime = hub:get("user")
            if runtime then
                local list = runtime:batches()
                batches = #list
            end
        end

        out.user = {
            configured = configured,
            loaded     = loaded,
            batches    = batches,
        }
    end

    ------------------------------------------------------------
    -- VENDORS RESOURCE
    ------------------------------------------------------------

    do
        local configured = hub:is_configured("vendors")
        local loaded     = hub:is_loaded("vendors")

        local batches = 0

        if loaded then
            local runtime = hub:get("vendors")
            if runtime then
                batches = #(runtime:batches())
            end
        end

        out.vendors = {
            configured = configured,
            loaded     = loaded,
            batches    = batches,
        }
    end

    ------------------------------------------------------------
    -- LEDGER CONTEXT
    ------------------------------------------------------------

    do
        local ledger_id =
            state:get_context("active_ledger") or "default"

        out.ledger = {
            ledger_id = ledger_id,
        }
    end

    return out
end

----------------------------------------------------------------
-- Inspect (Full State Snapshot)
----------------------------------------------------------------
-- Returns raw internal state tables.
-- Intended for debugging / TUI inspection only.

---@return table
function Surface:inspect()
    return {
        context   = self.state:context_table(),
        resources = self.state:resources_table(),
        results   = self.state.results,
    }
end

return Surface
