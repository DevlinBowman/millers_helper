-- system/app/surface/vendor_reference.lua

local VendorRefSvc = require("system.services.vendor_reference_service")
local Storage      = require("system.infrastructure.storage.controller")

return function(Surface)

    function Surface:vendor_reference(req)

        local result = VendorRefSvc.handle(req)

        if not result.ok then
            return result
        end

        if req.action == "commit" then
            local vendor = req.vendor
            local path = Storage.vendor_cache_root() .. "/" .. vendor .. ".csv"

            self.state:set_resource("vendors", {
                inputs = { path },
                opts   = { category = "board" }
            })

            if self.hub.invalidate then
                self.hub:invalidate("vendors")
            end
        end

        return result
    end

    function Surface:vendor_reference_commit(vendor, rows, opts)
        return self:vendor_reference({
            action = "commit",
            vendor = vendor,
            rows   = rows,
            opts   = opts,
        })
    end

end
