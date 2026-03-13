-- system/pipeline/enrichment/providers.lua

local PricingDomain = require("core.domain.pricing").controller

local Providers = {}

------------------------------------------------------------
-- board_prices provider
------------------------------------------------------------
-- Pure capability resolver
-- env → domain result
------------------------------------------------------------

local function provide_board_prices(app, selector, env)

    ------------------------------------------------------------
    -- Resolve job batch (supports envelope or direct batch)
    ------------------------------------------------------------

    local job_source = env.job
    local job_batch

    if type(job_source) ~= "table" then
        return nil
    end

    -- envelope case
    if type(job_source.batch) == "function" then
        job_batch = job_source:batch()

    -- already a batch
    elseif type(job_source.boards) == "table" then
        job_batch = job_source
    else
        return nil
    end

    if type(job_batch) ~= "table" then
        return nil
    end

    if type(job_batch.boards) ~= "table" then
        return nil
    end

    ------------------------------------------------------------
    -- Resolve pricing basis
    ------------------------------------------------------------

    local basis =
        env.pricing_basis
        or "vendor_anchor"

    ------------------------------------------------------------
    -- Resolve vendor batches
    ------------------------------------------------------------

    local vendor_batches =
        env.vendors or {}

    ------------------------------------------------------------
    -- Resolve options
    ------------------------------------------------------------

    local opts =
        env.opts or {}

    ------------------------------------------------------------
    -- Execute pricing domain
    ------------------------------------------------------------

    local result =
        PricingDomain.run(
            job_batch,
            basis,
            opts,
            vendor_batches
        )

    if not result then
        return nil
    end

    ------------------------------------------------------------
    -- Return capability result
    ------------------------------------------------------------

    return {
        ok         = true,
        capability = "board_prices",
        result     = result
    }
end

Providers.board_prices = provide_board_prices

------------------------------------------------------------
-- vendor_prices provider
------------------------------------------------------------

local function provide_vendor_prices(_, _, env)
    local vendors =
        env.vendors or {}

    for _, batch in ipairs(vendors) do
        for _, board in ipairs(batch.boards or {}) do
            if type(board.bf_price) == "number"
                and board.bf_price > 0 then
                return {
                    ok = true,
                    capability = "vendor_prices"
                }
            end
        end
    end

    return nil
end

Providers.vendor_prices = provide_vendor_prices

return Providers
