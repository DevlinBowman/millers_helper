-- system/app/surface/ingest.lua

local IngestSvc = require("system.services.ingest_service")

return function(Surface)

    function Surface:run_ingest(opts)
        return IngestSvc.handle(opts)
    end

end
