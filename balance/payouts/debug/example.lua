-- example.lua
--
-- Debug / test entrypoint for payout system.
-- This file is NOT production code.
-- It exists to exercise the adapter, pipeline, and view layers.

local Adapter = require("balance.payouts.adapter")
local View    = require("balance.payouts.internal.view")

----------------------------------------------------------------
-- Configuration overrides (case-by-case)
----------------------------------------------------------------
local overrides = {
    job = {
        total_bf = 1066,
        pricing_method = "total_value",
        job_total = 4745.00,
        -- sale_price_per_bf = 3.98, -- unused when pricing_method = total_value
    },

    -- Uncomment to test missing values / bad inputs:
    -- job = { pricing_method = "total_value" },        -- missing total_bf
    -- job = { total_bf = 0, sale_price_per_bf = 3.98 },-- invalid bf
    -- job = { total_bf = 1066, pricing_method = "???"},
    -- job = { total_bf = 1066, pricing_method = "per_bf" }, -- missing price

    contributions = {
        -- override or add parties safely
        -- A = { labor = 2.00 },
        -- X = { logs = 0.25, profit = 0.10 },
    },

    -- categories = {
    --     unknown = { type = "cost_bf" }, -- test unknown category
    -- },
}

----------------------------------------------------------------
-- Run adapter
----------------------------------------------------------------
local result, total_bf, spec, signals = Adapter.run(overrides)

----------------------------------------------------------------
-- Signal handling
----------------------------------------------------------------
local function summarize_signals(sig)
    print("")
    print("SIGNAL SUMMARY")
    print(string.rep("-", 50))
    print(string.format(
        "Errors: %d  Warnings: %d  Info: %d",
        sig.counts.error or 0,
        sig.counts.warn  or 0,
        sig.counts.info  or 0
    ))
end

if signals.has_error then
    print("")
    print("FATAL ERRORS DETECTED — RESULT MAY BE INCOMPLETE")
    summarize_signals(signals)
else
    summarize_signals(signals)
end

----------------------------------------------------------------
-- Print payout breakdown
----------------------------------------------------------------
View.print_payout_tree(result, total_bf or 0, {
    show_signals = true,  -- toggle to hide/show full signal dump
})

----------------------------------------------------------------
-- Optional programmatic inspection
----------------------------------------------------------------
-- Example: assert profit pool is non-negative
if result.profit and result.profit.pool and result.profit.pool < 0 then
    error("unexpected negative profit pool")
end

-- Example: dump raw structures for REPL inspection
-- print(require("inspect")(result))
-- print(require("inspect")(spec))
