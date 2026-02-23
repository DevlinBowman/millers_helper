-- system/app/surface/invoice.lua

local InvoiceSvc = require("system.services.invoice_service")

return function(Surface)

    function Surface:run_invoice(opts)
        return InvoiceSvc.handle({
            state = self.state,
            hub   = self.hub,
            opts  = opts
        })
    end

end
