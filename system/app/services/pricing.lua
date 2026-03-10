-- system/app/services/pricing.lua

local PricingDomain  = require("core.domain.pricing").controller
local Contracts      = require("core.domain.pricing.contracts")
local Compatibility  = require("system.compatibility.controller")
local Mutator        = require("system.runtime.mutator")

---@class AppPricingService
local Pricing = {}
Pricing.__index = Pricing

function Pricing.new(app)
    return setmetatable({
        __app = app
    }, Pricing)
end

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

---@param selector integer|string|nil
---@return table
function Pricing:_load_user_batch(selector)
    local runtime = self.__app:data():runtime()
    local envelope = runtime:require("user", "job", selector)

    assert(type(envelope.batch) == "function",
        "[pricing.service] runtime job missing batch()")

    return envelope:batch()
end

---@param selector integer|string|nil
---@param vendor_selector any
---@return table|nil
function Pricing:_resolve_vendor_env(selector, vendor_selector)
    if type(vendor_selector) == "table" and vendor_selector.kind == "vendor" then
        return vendor_selector
    end

    local runtime = self.__app:data():runtime()
    local resources = self.__app:data():resources()

    local vendor_list = resources:get("system", "vendor") or {}
    if #vendor_list == 0 then
        return nil
    end

    local index

    if vendor_selector == nil then
        index = 1
    elseif type(vendor_selector) == "number" then
        index = vendor_selector
    elseif type(vendor_selector) == "string" then
        for i, entry in ipairs(vendor_list) do
            if entry.id == vendor_selector then
                index = i
                break
            end
        end
    end

    if not index then
        return nil
    end

    local rt = runtime:require("system", "vendor", index)
    if type(rt.batch) ~= "function" then
        return nil
    end

    local batch = rt:batch()

    return {
        kind  = "vendor",
        items = batch.boards,
        meta  = {
            name = batch.id or vendor_selector or vendor_list[index].id
        }
    }
end

------------------------------------------------------------
-- Resolve Only (no mutation)
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Pricing:resolve(selector, opts)
    opts = opts or {}

    local batch = self:_load_user_batch(selector)

    local basis = opts.pricing_basis or opts.basis
    if not basis then
        if batch.order
            and batch.order.use == "sale"
            and type(batch.order.value) == "number"
            and batch.order.value > 0
        then
            basis = "reverse_order_value"
        else
            basis = "vendor_anchor"
        end
    end

    local domain_opts = {
        allocations        = opts.allocations,
        compare            = opts.compare,
        percentage         = opts.percentage,
        profile            = opts.profile,
        target_total_value = opts.target_total_value,
    }

    domain_opts.vendor = self:_resolve_vendor_env(selector, opts.vendor)

    local env = Contracts.build_env(batch, basis, domain_opts)
    local compat = Compatibility.check("pricing", basis, env)

    if not compat.ok then
        return {
            ok = false,
            error = "compatibility_mismatch",
            missing = compat.missing,
            strategy = basis,
        }
    end

    local result = PricingDomain.run(batch, basis, domain_opts)

    return {
        ok = true,
        strategy = basis,
        result = result,
        provided = { "board_prices" }
    }
end

------------------------------------------------------------
-- Run + Apply
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Pricing:run(selector, opts)
    local resolved = self:resolve(selector, opts)

    if not resolved.ok then
        return resolved
    end

    return resolved
end

return Pricing
