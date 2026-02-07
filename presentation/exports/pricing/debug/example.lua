-- presentation/exports/pricing/debug/example.lua
--
-- Minimal debug harness for pricing.options
-- This file intentionally stubs a compare_model so the pricing
-- engine can be exercised without running the full ingest pipeline.

local PricingOptions = require("presentation.exports.pricing.options")

----------------------------------------------------------------
-- Stub compare_model (minimal but structurally valid)
----------------------------------------------------------------

local compare_model = {
    rows = {
        {
            order_board = {
                physical = {
                    h = 1.0,
                    w = 6.0,
                    l = 12.0,
                    ct = 10,
                    bf_ea = 6.0,
                    bf_batch = 60.0,
                }
            },
            offers = {
                home_depot = {
                    pricing = {
                        ea = 18.00,
                        total = 180.00,
                    }
                },
                ace_ben_lomond = {
                    pricing = {
                        ea = 20.00,
                        total = 200.00,
                    }
                }
            }
        },
        {
            order_board = {
                physical = {
                    h = 2.0,
                    w = 6.0,
                    l = 16.0,
                    ct = 5,
                    bf_ea = 16.0,
                    bf_batch = 80.0,
                }
            },
            offers = {
                home_depot = {
                    pricing = {
                        ea = 45.00,
                        total = 225.00,
                    }
                },
                ace_ben_lomond = {
                    pricing = {
                        ea = 50.00,
                        total = 250.00,
                    }
                }
            }
        }
    },

    totals = {
        input = { total = 0 },
        home_depot = { total = 405.00 },
        ace_ben_lomond = { total = 450.00 },
    }
}

----------------------------------------------------------------
-- Cost model
----------------------------------------------------------------

local cost = {
    labor_per_bf    = 0.75,
    overhead_per_bf = 0.40,
    other_per_bf    = 0.00,
    flat_per_job    = 0.00,
}

----------------------------------------------------------------
-- Strategy
----------------------------------------------------------------

local strategy = {
    discounts = { 0.00, 0.05, 0.10 },
}

----------------------------------------------------------------
-- Run
----------------------------------------------------------------

local result = PricingOptions.build(compare_model, cost, strategy)
PricingOptions.print(result)
