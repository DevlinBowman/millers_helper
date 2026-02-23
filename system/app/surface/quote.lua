local QuoteSvc = require("system.services.quote_service")

local Quote = {}
Quote.__index = Quote

function Quote.new(surface)
    local self = setmetatable({}, Quote)
    self._surface = surface
    return self
end

function Quote:run(opts)
    return QuoteSvc.handle({
        state = self._surface.state,
        hub   = self._surface.hub,
        opts  = opts
    })
end

return Quote
