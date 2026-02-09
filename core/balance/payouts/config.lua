-- config.lua
--
-- Mutable configuration for payout runs.
-- Safe defaults + override-friendly.

local Config = {}

---@class CategoryMeta
---@field type string  -- "cost_bf" | "cost_abs" | "profit_pct"

---@class PayoutConfig
---@field categories table<string, CategoryMeta>
---@field job JobSpec
---@field contributions table<string, table<string, number>>

----------------------------------------------------------------
-- Categories
----------------------------------------------------------------
Config.categories = {
    logs     = { type = "cost_bf" },
    property = { type = "cost_bf" },
    labor    = { type = "cost_bf" },
    sales    = { type = "cost_bf" },
    delivery = { type = "cost_bf" },
    bonus    = { type = "cost_abs" },
    profit   = { type = "profit_pct" },
}

----------------------------------------------------------------
-- Job configuration
----------------------------------------------------------------
Config.job = {
    total_bf = nil,              -- REQUIRED
    pricing_method = "per_bf",   -- "per_bf" | "total_value"

    sale_price_per_bf = nil,     -- used when pricing_method = per_bf
    job_total         = nil,     -- used when pricing_method = total_value
}

----------------------------------------------------------------
-- Party contributions
----------------------------------------------------------------
Config.contributions = {
    A = {
        labor = 1.50,
    },
    B = {
        logs     = 0.40,
        property = 0.05,
        profit   = 0.50,
    },
    C = {
        logs     = 0.40,
        property = 0.05,
        sales    = 0.30,
        profit   = 0.50,
        bonus    = 500,
    },
}

return Config
