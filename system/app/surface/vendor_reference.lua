-- system/app/surface/vendor_reference.lua

local VendorRefSvc = require("system.services.vendor_reference_service")

local VendorReference = {}
VendorReference.__index = VendorReference

function VendorReference.new(surface)
    local self = setmetatable({}, VendorReference)
    self._surface = surface
    return self
end

function VendorReference:run(req)
    local result = VendorRefSvc.handle(req)
    if not result.ok then
        return result
    end

    -- If canonical vendor cache changed, refresh system vendors
    if req.action == "commit" then
        local resources = self._surface.resources
        if resources
            and resources.system
            and resources.system.vendors
            and resources.system.vendors.refresh_from_cache
        then
            resources.system.vendors:refresh_from_cache()
        end
    end

    return result
end

function VendorReference:commit(vendor, rows, opts)
    return self:run({
        action = "commit",
        vendor = vendor,
        rows   = rows,
        opts   = opts,
    })
end

return VendorReference
