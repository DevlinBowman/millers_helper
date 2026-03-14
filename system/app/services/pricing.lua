-- system/app/services/pricing.lua

local PricingDomain = require("core.domain.pricing").controller

---@class AppPricingService
---@field private __app Surface
local Pricing = {}
Pricing.__index = Pricing

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppPricingService
function Pricing.new(app)
    return setmetatable({
        __app = app
    }, Pricing)
end

------------------------------------------------------------
-- Public Run
------------------------------------------------------------

---@param ctx table|nil
---@return table
function Pricing:run(ctx)

    ------------------------------------------------
    -- Execution Target
    ------------------------------------------------

    local target =
        ctx and ctx.target

    assert(type(target) == "table",
        "[pricing.service] execution target missing")

    assert(type(target.batch) == "table",
        "[pricing.service] target batch missing")

    assert(type(target.boards) == "table",
        "[pricing.service] target boards missing")

    local job_batch =
        target.batch

    ------------------------------------------------
    -- Vendor Batches
    ------------------------------------------------

    local vendor_batches =
        ctx and ctx.env and ctx.env.vendors

    assert(type(vendor_batches) == "table",
        "[pricing.service] vendor batches missing")

    ------------------------------------------------
    -- Strategy
    ------------------------------------------------

    local strategy =
        ctx and ctx.strategy

    if not strategy then
        strategy = "vendor_anchor"
    end

    ------------------------------------------------
    -- Options
    ------------------------------------------------

    local opts =
        ctx and ctx.env and ctx.env.opts or {}

    ------------------------------------------------
    -- Domain Execution
    ------------------------------------------------

    return PricingDomain.run(
        job_batch,
        strategy,
        opts,
        vendor_batches
    )
end

return Pricing
