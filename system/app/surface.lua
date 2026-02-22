-- system/app/surface.lua
--
-- Application boundary surface.
-- Owns:
--   • Persisted State
--   • RuntimeHub (ephemeral)
--   • Service orchestration
--
-- Does NOT:
--   • Load runtimes directly
--   • Perform domain logic
--   • Persist runtime objects

local Persistence = require("system.app.persistence")
local RuntimeHub  = require("system.app.runtime_hub")

local CompareSvc  = require("system.services.compare_service")
local QuoteSvc    = require("system.services.quote_service")
local InvoiceSvc  = require("system.services.invoice_service")
local IngestSvc = require("system.services.ingest_service")

local Surface = {}
Surface.__index = Surface

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function Surface.new(opts)
    opts = opts or {}

    local state = Persistence.load(opts.persistence)

    local self = setmetatable({}, Surface)

    self.state = state
    self.hub   = RuntimeHub.new(state:resources_table())

    return self
end

----------------------------------------------------------------
-- Resource Management (Persisted Specs)
----------------------------------------------------------------

function Surface:set_resource(name, input, opts)
    return self.state:set_resource(name, {
        input = input,
        opts  = opts or {}
    })
end

function Surface:get_resource(name)
    return self.state:get_resource(name)
end

function Surface:clear_resource(name)
    return self.state:clear_resource(name)
end

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

function Surface:run_compare(opts)
    return CompareSvc.handle({
        state = self.state,
        hub   = self.hub,
        opts  = opts
    })
end

function Surface:run_quote(opts)
    return QuoteSvc.handle({
        state = self.state,
        hub   = self.hub,
        opts  = opts
    })
end

function Surface:run_invoice(opts)
    return InvoiceSvc.handle({
        state = self.state,
        hub   = self.hub,
        opts  = opts
    })
end

function Surface:run_ingest(opts)
    return IngestSvc.handle(opts)
end

----------------------------------------------------------------
-- Persistence
----------------------------------------------------------------

function Surface:save(opts)
    return Persistence.save(self.state, opts)
end

function Surface:get_state()
    return self.state
end

----------------------------------------------------------------
-- Status (Runtime Introspection)
----------------------------------------------------------------

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

function Surface:inspect()
    return {
        context   = self.state:context_table(),
        resources = self.state:resources_table(),
        results   = self.state.results,
    }
end

return Surface
