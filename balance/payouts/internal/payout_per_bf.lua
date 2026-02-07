-- payout_per_bf.lua
--
-- Per-bf + absolute cost + profit-percent payout engine with signals.

local Signals = require("core.diagnostics.signals")

local Payout = {}

---@class PayoutResult
---@field revenue table
---@field costs table
---@field profit table
---@field parties table<string, table<string, number>>
---@field signals SignalBag

local function ensure(tbl, key)
    if not tbl[key] then
        tbl[key] = {}
    end
    return tbl[key]
end

---@param total_bf number
---@param sale_price_per_bf number
---@param categories table<string, CategoryMeta>
---@param contributions table<string, table<string, number>>
---@param sig SignalBag
---@return PayoutResult
function Payout.compute_payouts(total_bf, sale_price_per_bf, categories, contributions, sig)
    sig = sig or Signals.new()

    local out = {
        revenue = {},
        costs   = {},
        profit  = {},
        parties = {},
        signals = sig,
    }

    if type(total_bf) ~= "number" or total_bf <= 0 then
        Signals.add(sig, "error", "BAD_TOTAL_BF", "job.total_bf", "total_bf must be a number > 0", { got = total_bf })
        return out
    end

    if type(sale_price_per_bf) ~= "number" or sale_price_per_bf < 0 then
        Signals.add(sig, "error", "BAD_SALE_PRICE_BF", "job.sale_price_per_bf", "sale_price_per_bf must be a number >= 0", { got = sale_price_per_bf })
        return out
    end

    if type(categories) ~= "table" then
        Signals.add(sig, "error", "CATEGORIES_NOT_TABLE", "categories", "categories must be a table", { got = type(categories) })
        return out
    end

    if type(contributions) ~= "table" then
        Signals.add(sig, "error", "CONTRIB_NOT_TABLE", "contributions", "contributions must be a table", { got = type(contributions) })
        return out
    end

    ------------------------------------------------------------
    -- Revenue
    ------------------------------------------------------------
    local gross_revenue = total_bf * sale_price_per_bf
    out.revenue.gross = gross_revenue

    ------------------------------------------------------------
    -- Costs
    ------------------------------------------------------------
    local total_cost = 0

    for party, rates in pairs(contributions) do
        if type(rates) ~= "table" then
            Signals.add(sig, "error", "PARTY_RATES_NOT_TABLE", ("contributions.%s"):format(tostring(party)), "party contribution must be a table", { got = type(rates) })
        else
            for category, value in pairs(rates) do
                local meta = categories[category]

                if meta == nil then
                    -- allow unknown keys, but signal
                    Signals.add(sig, "warn", "UNKNOWN_CATEGORY", ("contributions.%s.%s"):format(tostring(party), tostring(category)), "category not declared in categories; ignoring", { party = party, category = category, value = value })
                elseif category == "profit" then
                    -- profit handled later
                else
                    if type(value) ~= "number" then
                        Signals.add(sig, "error", "NON_NUMERIC_VALUE", ("contributions.%s.%s"):format(tostring(party), tostring(category)), "contribution value must be numeric", { got = value })
                    else
                        if meta.type == "cost_bf" then
                            local dollars = value * total_bf
                            ensure(out.parties, party)[category] = dollars
                            total_cost = total_cost + dollars

                        elseif meta.type == "cost_abs" then
                            local dollars = value
                            ensure(out.parties, party)[category] = dollars
                            total_cost = total_cost + dollars

                        elseif meta.type == "profit_pct" then
                            -- profit category is expected to be named "profit"
                            -- if user declares other profit_pct categories, they will be ignored by this engine
                            Signals.add(sig, "warn", "PROFIT_PCT_NON_PROFIT_KEY", ("categories.%s"):format(tostring(category)), "profit_pct categories are only applied via contributions.<party>.profit; ignoring key", { category = category })
                        else
                            Signals.add(sig, "error", "UNKNOWN_CATEGORY_TYPE", ("categories.%s.type"):format(tostring(category)), "unknown category type", { got = meta.type })
                        end
                    end
                end
            end
        end
    end

    out.costs.total = total_cost

    ------------------------------------------------------------
    -- Profit pool
    ------------------------------------------------------------
    local profit_pool = gross_revenue - total_cost
    out.profit.pool = profit_pool

    if profit_pool < 0 then
        Signals.add(sig, "error", "NEGATIVE_PROFIT_POOL", "profit.pool", "costs exceed revenue", { gross_revenue = gross_revenue, total_cost = total_cost, profit_pool = profit_pool })
        out.profit.error = "costs exceed revenue"
        return out
    end

    ------------------------------------------------------------
    -- Profit distribution
    ------------------------------------------------------------
    local pct_sum = 0
    for party, rates in pairs(contributions) do
        if type(rates) == "table" then
            local pct = rates.profit or 0
            if pct ~= 0 and type(pct) ~= "number" then
                Signals.add(sig, "error", "NON_NUMERIC_PROFIT_PCT", ("contributions.%s.profit"):format(tostring(party)), "profit percent must be numeric", { got = pct })
            else
                if type(pct) == "number" and pct < 0 then
                    Signals.add(sig, "warn", "NEGATIVE_PROFIT_PCT", ("contributions.%s.profit"):format(tostring(party)), "negative profit pct is unusual", { got = pct })
                end
                pct_sum = pct_sum + (type(pct) == "number" and pct or 0)
            end
        end
    end

    if pct_sum > 1.0 + 1e-6 then
        Signals.add(sig, "error", "PROFIT_PCT_EXCEEDS_100", "contributions.*.profit", "profit percentages exceed 100%", { sum = pct_sum })
        return out
    end

    if pct_sum < 1.0 - 1e-6 then
        Signals.add(sig, "warn", "PROFIT_PCT_UNDER_100", "contributions.*.profit", "profit percentages sum to less than 100% (unallocated profit)", { sum = pct_sum })
    end

    for party, rates in pairs(contributions) do
        if type(rates) == "table" then
            local pct = rates.profit or 0
            if type(pct) == "number" and pct > 0 then
                local dollars = profit_pool * pct
                ensure(out.parties, party).profit = dollars
            end
        end
    end

    ------------------------------------------------------------
    -- Party totals
    ------------------------------------------------------------
    for party, buckets in pairs(out.parties) do
        local total = 0
        for _, v in pairs(buckets) do
            total = total + v
        end
        buckets.total = total
    end

    return out
end

return Payout
