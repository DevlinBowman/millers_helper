-- system/enrichment/providers.lua

local PricingDomain = require("core.domain.pricing").controller

local Providers = {}

------------------------------------------------------------
-- board_prices provider
------------------------------------------------------------
-- Pure capability resolver
-- env → domain result
------------------------------------------------------------

local function provide_board_prices(app, selector, env)

    local job = env.job
    if type(job) ~= "table" then
        return nil
    end

    if type(job.boards) ~= "table" then
        return nil
    end

    local basis =
        env.pricing_basis
        or "vendor_anchor"

    local opts =
        env.opts
        or {}

    local result =
        PricingDomain.run(
            job,
            basis,
            opts
        )

    if not result then
        return nil
    end

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
