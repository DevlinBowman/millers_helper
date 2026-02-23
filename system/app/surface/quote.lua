-- system/app/surface/quote.lua

local QuoteSvc = require("system.services.quote_service")

return function(Surface)

    function Surface:run_quote(opts)
        return QuoteSvc.handle({
            state = self.state,
            hub   = self.hub,
            opts  = opts
        })
    end

end
