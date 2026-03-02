-- system/app/services/vendor.lua

local Runtime        = require("core.domain.runtime").controller
local VendorRef      = require("core.domain.vendor_reference").controller
local VendorRegistry = require("core.domain.vendor_reference").registry
local FSHelpers      = require("system.app.fs_helpers")

---@class VendorServiceUpdateParams
---@field vendor_name string
---@field vendor_batch table        -- RuntimeBatch (required)
---@field existing_vendor table|nil -- optional
---@field opts table|nil            -- optional

---@class VendorServiceUpdateResponse
---@field result VendorReferenceResult
---@field cache_path string
---@field vendor_name string

---@class AppVendorService
local Vendor = {}
Vendor.__index = Vendor

function Vendor.new(app)
    return setmetatable({ __app = app }, Vendor)
end

---@param params VendorServiceUpdateParams
---@return VendorServiceUpdateResponse
---@param params VendorServiceUpdateParams
---@return VendorServiceUpdateResponse
---@param params VendorServiceUpdateParams
---@return VendorServiceUpdateResponse
function Vendor:update(params)
    assert(type(params) == "table", "[vendor] params required")

    assert(type(params.vendor_name) == "string" and params.vendor_name ~= "",
        "[vendor] vendor_name required")

    assert(params.vendor_batch ~= nil,
        "[vendor] vendor_batch required")

    local normalized =
        VendorRegistry.vendor.normalize_name(params.vendor_name)

    assert(normalized, "[vendor] invalid vendor_name")

    ------------------------------------------------------------
    -- Normalize vendor_batch → canonical RuntimeBatch
    ------------------------------------------------------------

    local vendor_batch

    -- RuntimeResult façade
    if type(params.vendor_batch) == "table"
        and type(params.vendor_batch.batch) == "function" then

        vendor_batch = params.vendor_batch:batch()

    -- Already canonical RuntimeBatch
    elseif type(params.vendor_batch) == "table"
        and type(params.vendor_batch.boards) == "table" then

        vendor_batch = params.vendor_batch

    else
        error("[vendor] vendor_batch must be RuntimeResult or RuntimeBatch")
    end

    assert(type(vendor_batch.boards) == "table",
        "[vendor] canonical vendor_batch.boards required")

    ------------------------------------------------------------
    -- Resolve canonical cache path
    ------------------------------------------------------------

    local helpers     = FSHelpers.new()
    local vendor_root = self.__app:fs():store():vendor()
    local cache_path  = helpers:child(vendor_root, normalized .. ".csv")

    ------------------------------------------------------------
    -- Load existing vendor rows if present
    ------------------------------------------------------------

    local existing_vendor = params.existing_vendor

    if existing_vendor == nil and helpers:exists(cache_path) then
        local runtime = Runtime.load_strict(cache_path)
        existing_vendor = runtime:batch().boards
    end

    ------------------------------------------------------------
    -- Domain update
    ------------------------------------------------------------

    local result = VendorRef.update(
        normalized,
        vendor_batch,
        existing_vendor,
        params.opts or {}
    )

    -- Enforce canonical domain result before writing
    result:require_no_errors()

    ------------------------------------------------------------
    -- Persist canonical result
    ------------------------------------------------------------

    result:write_strict(cache_path, "delimited")

    ------------------------------------------------------------
    -- Return structured service response
    ------------------------------------------------------------

    return {
        vendor_name = normalized,
        cache_path  = cache_path,
        result      = result,
    }
end

return Vendor
