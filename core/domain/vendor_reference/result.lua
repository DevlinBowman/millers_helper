-- core/domain/vendor_reference/result.lua
--
-- VendorReferenceResult façade.
-- Wraps update DTO and exposes semantic accessors + policy.

local Signals = require("core.domain.vendor_reference.internal.signals")
local VendorPackage = require("core.domain.vendor_reference.package_result")
local Persist = require("platform.persist").controller

local VendorReferenceResult = {}
VendorReferenceResult.__index = VendorReferenceResult

function VendorReferenceResult.new(dto)
    assert(type(dto) == "table", "VendorReferenceResult requires DTO")
    return setmetatable({ __data = dto }, VendorReferenceResult)
end

function VendorReferenceResult:vendor()
    return self.__data.vendor
end


function VendorReferenceResult:rows()
    return self.__data.rows or {}
end

function VendorReferenceResult:report()
    return self.__data.report or {}
end

function VendorReferenceResult:signals()
    return self.__data.signals
end

function VendorReferenceResult:package()
    return VendorPackage.new(self.__data.vendor_package)
end

function VendorReferenceResult:has_errors()
    return Signals.has_errors(self.__data.signals)
end

function VendorReferenceResult:require_no_errors()
    assert(not self:has_errors(), "[vendor_reference] update failed")
    return self
end

----------------------------------------------------------------
-- Persistence
----------------------------------------------------------------

function VendorReferenceResult:write(path, codec, opts)
    return Persist.write(path, self:package():raw(), codec, opts)
end

function VendorReferenceResult:write_strict(path, codec, opts)
    return Persist.write_strict(path, self:package():raw(), codec, opts)
end

return VendorReferenceResult
