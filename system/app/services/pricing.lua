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
-- Internal: Normalize Runtime Selector
------------------------------------------------------------

---@param selector any
---@return number|string|nil
local function normalize_runtime_selector(selector)

    if selector == nil then
        return nil
    end

    local t = type(selector)

    if t == "number" or t == "string" then
        return selector
    end

    if t == "table" then

        if selector.resource then
            return selector.resource
        end

        if selector.batch then
            return selector.batch
        end

        if selector.id then
            return selector.id
        end

    end

    return nil
end

------------------------------------------------------------
-- Public Run
------------------------------------------------------------

---@param ctx table|nil
---@return table
function Pricing:run(ctx)

    local data    = self.__app:data()
    local runtime = data:runtime()
    local slots   = data:slots()

    ------------------------------------------------
    -- Resolve Job Envelope (resource level)
    ------------------------------------------------

    local job_env

    if ctx and ctx.env and ctx.env.job then
        job_env = ctx.env.job
    else
        job_env = runtime:require("user","job")
    end

    assert(type(job_env)=="table",
        "[pricing.service] job envelope missing")

    ------------------------------------------------
    -- Resolve Job Batch (batch level)
    ------------------------------------------------

    local job_batch

    local selector = slots:get_selection("user","job")

    if type(selector) == "table" and selector.batch then

        local batches = job_env.__batches or {}

        local idx = selector.batch

        if idx > #batches then
            idx = #batches
        elseif idx < 1 then
            idx = 1
        end

        job_batch = batches[idx]

    else

        job_batch = job_env:batch()

    end

    assert(type(job_batch)=="table",
        "[pricing.service] job batch missing")

    ------------------------------------------------
    -- Resolve Vendor Batches
    ------------------------------------------------

    local vendor_batches

    if ctx and ctx.env and ctx.env.vendors then

        vendor_batches = ctx.env.vendors

    else

        local selector = slots:get_selection("system","vendor")

        if type(selector) == "table" and selector.batch then

            local env = runtime:require("system","vendor")
            local batches = env.__batches or {}

            local idx = selector.batch

            if idx > #batches then
                idx = #batches
            elseif idx < 1 then
                idx = 1
            end

            vendor_batches = { batches[idx] }

        else

            vendor_batches = runtime:batches("system","vendor")

        end

    end

    ------------------------------------------------
    -- Resolve Strategy
    ------------------------------------------------

    local strategy

    if ctx and ctx.strategy then

        strategy = ctx.strategy

    else

        local intent =
            data:intent():get("pricing") or {}

        strategy =
            intent.basis or "vendor_anchor"

    end

    ------------------------------------------------
    -- Options
    ------------------------------------------------

    local opts =
        ctx and ctx.opts or {}

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
