-- system/app/services/vendor.lua

local VendorRef      = require("core.domain.vendor_reference").controller
local VendorRegistry = require("core.domain.vendor_reference").registry
local FSHelpers      = require("system.app.fs.helpers")

---@class AppVendorService
---@field private __app Surface
---@field private __helpers FSHelpers
local Vendor = {}
Vendor.__index = Vendor

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppVendorService
function Vendor.new(app)
    return setmetatable({
        __app     = app,
        __helpers = FSHelpers.new()
    }, Vendor)
end

------------------------------------------------------------
-- Run Vendor Reference Push
------------------------------------------------------------

---@param ctx table
---@return table
function Vendor:run(ctx)

    assert(type(ctx) == "table", "[vendor.service] ctx required")
    assert(type(ctx.env) == "table", "[vendor.service] ctx.env missing")
    assert(type(ctx.env.vendor) == "table", "[vendor.service] ctx.env.vendor missing")

    ------------------------------------------------------------
    -- Resolve vendor batch
    ------------------------------------------------------------

    local vendor_batch =
        ctx.env.vendor:batch()

    assert(type(vendor_batch) == "table",
        "[vendor.service] vendor batch missing")

    assert(type(vendor_batch.boards) == "table",
        "[vendor.service] vendor boards missing")

    ------------------------------------------------------------
    -- Descriptor + normalization
    ------------------------------------------------------------

    local descriptor =
        ctx.env.vendor.descriptor

    assert(type(descriptor) == "table",
        "[vendor.service] vendor descriptor missing")

    local vendor_name =
        VendorRegistry.vendor.normalize_name(descriptor.id)

    assert(type(vendor_name) == "string" and vendor_name ~= "",
        "[vendor.service] vendor normalization failed")

    ------------------------------------------------------------
    -- Canonical vendor store path
    ------------------------------------------------------------

    local vendor_root =
        self.__app:fs():store():vendor()

    local target_path =
        self.__helpers:child(vendor_root, vendor_name .. ".csv")

    local target_exists =
        self.__helpers:exists(target_path)

    ------------------------------------------------------------
    -- Domain execution
    ------------------------------------------------------------

    local result =
        VendorRef.run(
            vendor_name,
            vendor_batch.boards,
            target_path,
            ctx.opts or { codec = "delimited" }
        )

    ------------------------------------------------------------
    -- Result
    ------------------------------------------------------------

    return {
        ok          = true,
        stage       = target_exists and "overwrite" or "create",
        vendor_name = vendor_name,
        cache_path  = target_path,
        result      = result
    }
end

return Vendor
