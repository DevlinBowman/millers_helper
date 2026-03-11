-- system/enrichment/providers.lua

local Providers = {}

------------------------------------------------------------
-- board_prices provider
------------------------------------------------------------
-- Produces board pricing capability data for enrichment.
-- Does NOT call application services.
-- Returns pricing domain result for materialization.

Providers.board_prices = function(app, selector, env)

    print("\n[enrichment][provider.board_prices] BEGIN")
    print("[enrichment][provider.board_prices] selector:", selector)

    local Interpreter   = require("system.app.intent.interpreter")
    local PricingDomain = require("core.domain.pricing").controller

    local job = env.job

    if type(job) ~= "table" then
        print("[enrichment][provider.board_prices] job missing")
        return nil
    end

    if type(job.boards) ~= "table" then
        print("[enrichment][provider.board_prices] job.boards missing")
        return nil
    end

    print("[enrichment][provider.board_prices] board count:", #job.boards)

    ------------------------------------------------------------
    -- runtime + intent
    ------------------------------------------------------------

    local runtime = app:data():runtime()
    local intent  = app:data():intent():all()

    print("[enrichment][provider.board_prices] intent keys:")
    for k,_ in pairs(intent or {}) do
        print("   ", k)
    end

    ------------------------------------------------------------
    -- interpreted intent
    ------------------------------------------------------------

    local interpreted_ctx =
        Interpreter.build("pricing", runtime, intent) or {}

    print("[enrichment][provider.board_prices] interpreted pricing ctx:")
    for k,v in pairs(interpreted_ctx) do
        print("   ", k, type(v))
    end

    ------------------------------------------------------------
    -- merge opts
    ------------------------------------------------------------

    local pricing_opts = {}

    for key, value in pairs(env.opts or {}) do
        pricing_opts[key] = value
    end

    for key, value in pairs(interpreted_ctx) do
        pricing_opts[key] = value
    end

    print("[enrichment][provider.board_prices] pricing opts:")
    for k,v in pairs(pricing_opts) do
        print("   ", k, type(v))
    end

    ------------------------------------------------------------
    -- basis selection
    ------------------------------------------------------------

    local pricing_basis =
        pricing_opts.pricing_basis
        or pricing_opts.basis
        or "vendor_anchor"

    print("[enrichment][provider.board_prices] pricing basis:", pricing_basis)

    ------------------------------------------------------------
    -- board prices BEFORE
    ------------------------------------------------------------

    print("[enrichment][provider.board_prices] board prices BEFORE pricing:")

    for i,board in ipairs(job.boards) do
        print(
            "   ",
            i,
            board.id or board.label,
            "bf_price:",
            board.bf_price
        )
    end

    ------------------------------------------------------------
    -- run pricing domain
    ------------------------------------------------------------

    local pricing_result = PricingDomain.run(
        job,
        pricing_basis,
        pricing_opts
    )

    print("[enrichment][provider.board_prices] pricing domain returned:",
        pricing_result ~= nil)

    if not pricing_result then
        print("[enrichment][provider.board_prices] pricing domain FAILED")
        return nil
    end

    ------------------------------------------------------------
    -- board prices AFTER
    ------------------------------------------------------------

    print("[enrichment][provider.board_prices] board prices AFTER pricing:")

    for i,board in ipairs(job.boards) do
        print(
            "   ",
            i,
            board.id or board.label,
            "bf_price:",
            board.bf_price
        )
    end

    print("[enrichment][provider.board_prices] END")

    ------------------------------------------------------------
    -- return capability payload
    ------------------------------------------------------------

    return {
        ok = true,
        capability = "board_prices",
        result = pricing_result
    }
end


------------------------------------------------------------
-- vendor_prices provider
------------------------------------------------------------

Providers.vendor_prices = function(_, _, env)

    print("[enrichment][provider.vendor_prices] checking vendor boards")

    local vendors = env.vendors or {}

    for _, batch in ipairs(vendors) do
        for _, board in ipairs(batch.boards or {}) do
            if type(board.bf_price) == "number" and board.bf_price > 0 then
                print("[enrichment][provider.vendor_prices] vendor prices present")
                return {
                    ok = true,
                    capability = "vendor_prices"
                }
            end
        end
    end

    print("[enrichment][provider.vendor_prices] no vendor prices found")

    return nil
end

return Providers
