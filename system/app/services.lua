-- system/app/services.lua
--
-- Application-level services capability surface.
-- Provides access to orchestration services (compare, ledger, vendor, etc).

---@class AppServicesFacade
local Services = {}
Services.__index = Services

---@return AppServicesFacade
function Services.new()
    return setmetatable({}, Services)
end

------------------------------------------------------------
-- Service Stubs
------------------------------------------------------------

---Compare service entrypoint (stub).
function Services:compare()
    error("[app.services.compare] not implemented")
end

---Vendor reference service entrypoint (stub).
function Services:vendor()
    error("[app.services.vendor] not implemented")
end

---Ledger service entrypoint (stub).
function Services:ledger()
    error("[app.services.ledger] not implemented")
end

return Services
