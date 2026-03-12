-- system/app/services/pricing.lua

local PricingDomain = require("core.domain.pricing").controller

---@class AppPricingService
---@field private __app Surface
local Pricing   = {}
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

    local data =
        self.__app:data()

    local runtime =
        data:runtime()

    ------------------------------------------------
    -- Resolve job batch
    ------------------------------------------------

    local job_batch

    if ctx and ctx.env and ctx.env.job then

        job_batch =
            ctx.env.job:batch()

    else

        job_batch =
            runtime:require("user","job"):batch()

    end

    assert(type(job_batch) == "table",
        "[pricing.service] job batch missing")

    assert(type(job_batch.boards) == "table",
        "[pricing.service] job batch boards missing")

    ------------------------------------------------
    -- Resolve vendor batches
    ------------------------------------------------

    local vendor_batches =
        runtime:batches("system","vendor")

    ------------------------------------------------
    -- Options
    ------------------------------------------------

    local opts =
        ctx and ctx.opts or {}

    local basis =
        ctx and ctx.strategy or "vendor_anchor"

    ------------------------------------------------
    -- Domain execution
    ------------------------------------------------

    return PricingDomain.run(
        job_batch,
        basis,
        opts,
        vendor_batches
    )
end

return Pricing
