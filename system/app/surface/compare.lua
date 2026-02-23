-- system/app/surface/compare.lua

local CompareSvc = require("system.services.compare_service")

return function(Surface)

    function Surface:run_compare(opts)
        return CompareSvc.handle({
            state = self.state,
            hub   = self.hub,
            opts  = opts
        })
    end

end
