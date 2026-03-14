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
function Pricing:run(ctx)

    local target = ctx and ctx.target

    assert(type(target) == "table",
        "[pricing.service] execution target missing")

    local job_batch = target.batch

    ------------------------------------------------
    -- Vendor batches from execution resolver
    ------------------------------------------------

    local vendor_batches =
        ctx and ctx.env and ctx.env.vendors

    assert(type(vendor_batches) == "table" and #vendor_batches > 0,
        "[pricing.service] vendor batches missing")

    ------------------------------------------------
    -- Build domain vendor envelope from runtime
    ------------------------------------------------

    local vendor_env = {
        kind  = "vendor",
        items = {},
        meta  = {}
    }

    for _, batch in ipairs(vendor_batches) do

        local boards = batch.boards or {}

        for _, board in ipairs(boards) do
            vendor_env.items[#vendor_env.items + 1] = board
        end

    end

    if vendor_batches[1] and vendor_batches[1].id then
        vendor_env.meta.name = vendor_batches[1].id
    end

    ------------------------------------------------
    -- Strategy
    ------------------------------------------------

    local strategy =
        ctx and ctx.strategy or "vendor_anchor"

    ------------------------------------------------
    -- Options
    ------------------------------------------------

    local opts =
        ctx and ctx.env and ctx.env.opts or {}

    local intent =
        ctx and ctx.env and ctx.env.intent

    if intent and intent.get then

        local pricing_intent = intent:get("pricing")

        if type(pricing_intent) == "table" then
            for k, v in pairs(pricing_intent) do
                if opts[k] == nil then
                    opts[k] = v
                end
            end
        end
    end

    opts.vendor = vendor_env

    ------------------------------------------------
    -- Domain execution
    ------------------------------------------------

    return PricingDomain.run(
        job_batch,
        strategy,
        opts
    )
end

return Pricing
