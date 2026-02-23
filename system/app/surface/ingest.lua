-- system/app/surface/ingest.lua

local IngestSvc = require("system.services.ingest_service")

local Ingest = {}
Ingest.__index = Ingest

function Ingest.new(surface)
    local self = setmetatable({}, Ingest)
    self._surface = surface
    return self
end

function Ingest:run(opts)
    return IngestSvc.handle({
        state = self._surface.state,
        hub   = self._surface.hub,
        opts  = opts
    })
end

return Ingest
