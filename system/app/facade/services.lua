-- system/app/services.lua

local VendorService = require("system.app.services.vendor")

---@class AppServicesFacade
---@field private __app Surface
---@field private __vendor AppVendorService|nil
local Services = {}
Services.__index = Services

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppServicesFacade
function Services.new(app)

    ---@type AppServicesFacade
    local instance = setmetatable({
        __app    = app,
        __vendor = nil,
    }, Services)

    return instance
end

------------------------------------------------------------
-- Vendor Capability
------------------------------------------------------------

---@return AppVendorService
function Services:vendor()
    if self.__vendor == nil then
        ---@type AppVendorService
        local service = VendorService.new(self.__app)
        self.__vendor = service
    end

    ---@type AppVendorService
    return self.__vendor
end

------------------------------------------------------------
-- Inspect (Dev Only)
------------------------------------------------------------

---@return table
function Services:inspect()
    return {
        capabilities = { "vendor" },
        usage = "app:services():vendor():run(args)"
    }
end

return Services
