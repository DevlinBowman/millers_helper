local InvoiceSvc = require("system.services.invoice_service")

local Invoice = {}
Invoice.__index = Invoice

function Invoice.new(surface)
    local self = setmetatable({}, Invoice)
    self._surface = surface
    return self
end

function Invoice:run(opts)
    return InvoiceSvc.handle({
        state = self._surface.state,
        hub   = self._surface.hub,
        opts  = opts
    })
end

return Invoice
