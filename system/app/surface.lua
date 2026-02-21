local State        = require("system.app.state")
local Persistence  = require("system.app.persistence")

local CompareSvc   = require("system.services.compare_service")
local QuoteSvc     = require("system.services.quote_service")
local InvoiceSvc   = require("system.services.invoice_service")

local Surface = {}
Surface.__index = Surface

function Surface.new(opts)
    opts = opts or {}

    local state = Persistence.load(opts.persistence)
    state.resources = state.resources or {}
    state.results   = state.results   or {}

    local self = setmetatable({}, Surface)
    self.state = state

    return self
end

------------------------------------------------------------
-- Resource Management
------------------------------------------------------------

function Surface:set_resource(key, value)
    if type(key) ~= "string" then
        return false, "invalid resource key"
    end

    self.state.resources[key] = value
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

return Surface
