local State       = require("system.app.state")
local Persistence = require("system.app.persistence")

local CompareSvc  = require("system.services.compare_service")
local QuoteSvc    = require("system.services.quote_service")
local InvoiceSvc  = require("system.services.invoice_service")

local Surface     = {}
Surface.__index   = Surface

function Surface.new(opts)
    opts             = opts or {}

    local state      = Persistence.load(opts.persistence)
    local RuntimeHub = require("system.app.runtime_hub")
    local hub        = RuntimeHub.new(state.resources or {})

    state._hub       = hub
    state.resources  = state.resources or {}
    state.results    = state.results or {}

    local self       = setmetatable({}, Surface)
    self.state       = state

    return self
end

------------------------------------------------------------
-- Resource Management
------------------------------------------------------------

function Surface:set_resource(key, value)

    if type(key) ~= "string" or key == "" then
        return false, "invalid resource key"
    end

    self.state.resources = self.state.resources or {}
    self.state.resources[key] = value

    ------------------------------------------------------------
    -- Wire into RuntimeHub
    ------------------------------------------------------------

    local hub = self.state._hub
    if hub then
        if key == "order_path" then
            hub:set("user", value, { category = "user" })
        elseif key == "vendor_paths" and type(value) == "table" then
            hub:set("vendors", value, { category = "vendor" })
        end
    end

    return true
end

function Surface:get_resource(key)
    return self.state.resources[key]
end

------------------------------------------------------------
-- Services
------------------------------------------------------------

function Surface:run_compare(opts)
    return CompareSvc.handle({
        state = self.state,
        opts  = opts
    })
end

function Surface:run_quote(opts)
    return QuoteSvc.handle({
        state = self.state,
        opts  = opts
    })
end

function Surface:run_invoice(opts)
    return InvoiceSvc.handle({
        state = self.state,
        opts  = opts
    })
end

------------------------------------------------------------
-- Persistence
------------------------------------------------------------

function Surface:save(opts)
    return Persistence.save(self.state, opts)
end

function Surface:get_state()
    return self.state
end

------------------------------------------------------------
-- Status
------------------------------------------------------------

function Surface:status()

    local state = self.state
    local hub   = state._hub

    local out = {}

    ------------------------------------------------------------
    -- USER (orders / boards)
    ------------------------------------------------------------

    do
        local configured = hub and hub:is_configured("user") or false
        local loaded     = hub and hub:is_loaded("user") or false

        local batches = 0
        local active  = nil

        if loaded then
            local runtime = hub:get("user")
            if runtime then
                local list = runtime:batches()
                batches = #list
                active  = batches > 0 and 1 or nil
            end
        end

        out.user = {
            configured = configured,
            loaded     = loaded,
            batches    = batches,
            active     = active,
        }
    end

    ------------------------------------------------------------
    -- VENDORS
    ------------------------------------------------------------

    do
        local configured = hub and hub:is_configured("vendors") or false
        local loaded     = hub and hub:is_loaded("vendors") or false

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
    -- LEDGER
    ------------------------------------------------------------

    do
        local ledger_id =
            state.context
            and state.context.active_ledger
            or "default"

        out.ledger = {
            configured = true,
            ready      = true,
            ledger_id  = ledger_id,
        }
    end

    return out
end

------------------------------------------------------------
-- Inspect (Deep State View)
------------------------------------------------------------

function Surface:inspect(opts)

    opts = opts or {}
    local state = self.state
    local hub   = state._hub

    local out = {
        context  = state.context,
        resources = state.resources,
        results  = state.results,
        hub = {
            specs   = hub and hub:specs() or {},
            loaded  = {},
        }
    }

    if hub then
        for name, _ in pairs(hub:specs()) do
            if hub:is_loaded(name) then
                local runtime = hub:get(name)
                local batches = runtime and runtime:batches() or {}

                out.hub.loaded[name] = {
                    batch_count = #batches,
                    batches = {}
                }

                for i, batch in ipairs(batches) do
                    out.hub.loaded[name].batches[i] = {
                        order_present  = batch.order ~= nil,
                        boards_count   = batch.boards and #batch.boards or 0,
                        allocation     = batch.allocation ~= nil,
                        meta           = batch.meta,
                    }
                end
            else
                out.hub.loaded[name] = {
                    batch_count = 0,
                    batches = {}
                }
            end
        end
    end

    return out
end

return Surface
