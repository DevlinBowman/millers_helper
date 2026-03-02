-- system/app/services/vendor.lua

local VendorRef      = require("core.domain.vendor_reference").controller
local VendorRegistry = require("core.domain.vendor_reference").registry
local FSHelpers      = require("system.app.fs.helpers")

---@class AppVendorService
local Vendor = {}
Vendor.__index = Vendor

function Vendor.new(app)
    return setmetatable({
        __app = app,
        __helpers = FSHelpers.new()
    }, Vendor)
end

------------------------------------------------------------
-- Run vendor push with full validation + messaging
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Vendor:run(selector, opts)
    local data      = self.__app:data()
    local resources = data:resources()
    local runtime   = data:runtime()

    ------------------------------------------------------------
    -- 1. Validate user vendor resources
    ------------------------------------------------------------

    local user_list = resources:get("user", "vendor")

    if type(user_list) ~= "table" or #user_list == 0 then
        return {
            ok = false,
            stage = "no_user_vendor",
            message = "No user vendor resources are registered."
        }
    end

    ------------------------------------------------------------
    -- 2. Resolve selector
    ------------------------------------------------------------

    local index

    if selector == nil then
        if #user_list ~= 1 then
            return {
                ok = false,
                stage = "ambiguous_selector",
                message = "Multiple user vendors exist. Provide selector (index or id)."
            }
        end
        index = 1

    elseif type(selector) == "number" then
        index = selector

    elseif type(selector) == "string" then
        for i = 1, #user_list do
            if user_list[i].id == selector then
                index = i
                break
            end
        end
        if not index then
            return {
                ok = false,
                stage = "invalid_selector",
                message = "User vendor id not found: " .. selector
            }
        end

    else
        return {
            ok = false,
            stage = "invalid_selector_type",
            message = "Selector must be nil | number | string."
        }
    end

    local descriptor = user_list[index]
    if not descriptor then
        return {
            ok = false,
            stage = "descriptor_missing",
            message = "User vendor descriptor missing at index " .. tostring(index)
        }
    end

    ------------------------------------------------------------
    -- 3. Load runtime batch
    ------------------------------------------------------------

    local runtime_result
    local ok_rt, err = pcall(function()
        runtime_result = runtime:require("user", "vendor", index)
    end)

    if not ok_rt or not runtime_result then
        return {
            ok = false,
            stage = "runtime_load_failed",
            message = err or "Failed to load runtime vendor batch."
        }
    end

    if type(runtime_result.batch) ~= "function" then
        return {
            ok = false,
            stage = "invalid_runtime_shape",
            message = "Runtime vendor batch missing batch() method."
        }
    end

    local batch = runtime_result:batch()
    if type(batch.boards) ~= "table" then
        return {
            ok = false,
            stage = "invalid_batch_shape",
            message = "Runtime vendor batch missing boards table."
        }
    end

    ------------------------------------------------------------
    -- 4. Normalize vendor id
    ------------------------------------------------------------

    local normalized = VendorRegistry.vendor.normalize_name(descriptor.id)
    if not normalized then
        return {
            ok = false,
            stage = "normalize_failed",
            message = "Failed to normalize vendor id."
        }
    end

    ------------------------------------------------------------
    -- 5. Determine canonical target path
    ------------------------------------------------------------

    local helpers = self.__helpers
    local vendor_root = self.__app:fs():store():vendor()
    local target_path = helpers:child(vendor_root, normalized .. ".csv")

    local target_exists = helpers:exists(target_path)

    ------------------------------------------------------------
    -- 6. Domain run
    ------------------------------------------------------------

    local result = VendorRef.run(
        normalized,
        batch.boards,
        target_path,
        opts or { codec = "delimited" }
    )

    ------------------------------------------------------------
    -- 7. Success message
    ------------------------------------------------------------

    local message

    if target_exists then
        message = "Vendor '" .. normalized .. "' updated successfully (overwritten)."
    else
        message = "Vendor '" .. normalized .. "' created successfully."
    end

    return {
        ok = true,
        stage = target_exists and "overwrite" or "create",
        message = message,
        vendor_name = normalized,
        cache_path = target_path,
        result = result,
    }
end

return Vendor
