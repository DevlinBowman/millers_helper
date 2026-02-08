-- core/price_suggestion/model.lua
--
-- Price suggestion / scenario generator.
--
-- Input:
--   • compare_model (core.compare.model output)
--   • cost_model   (explicit business truth)
--   • strategy     (baseline + discounts)
--
-- Output:
--   • scenarios with revenue / cost / profit impact
--   • NO I/O

local Model = {}

----------------------------------------------------------------
-- Helpers (UNCHANGED)
----------------------------------------------------------------

local function round2(n)
    return math.floor((tonumber(n) or 0) * 100 + 0.5) / 100
end

local function safe_num(n)
    n = tonumber(n)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then return nil end
    return n
end

local function compute_job_bf_total(compare_model)
    local bf_total = 0
    for _, row in ipairs(compare_model.rows or {}) do
        local p = row.order_board and row.order_board.physical or {}
        local bf = safe_num(p.bf_batch)
        if not bf then
            bf = (safe_num(p.bf_ea) or 0) * (safe_num(p.ct) or 1)
        end
        bf_total = bf_total + bf
    end
    return bf_total
end

local function compute_costs(bf_total, cost_model)
    cost_model = cost_model or {}

    local labor_per_bf    = safe_num(cost_model.labor_per_bf)    or 0
    local overhead_per_bf = safe_num(cost_model.overhead_per_bf) or 0
    local other_per_bf    = safe_num(cost_model.other_per_bf)    or 0
    local flat_per_job    = safe_num(cost_model.flat_per_job)    or 0

    local labor    = round2(bf_total * labor_per_bf)
    local overhead = round2(bf_total * overhead_per_bf)
    local other    = round2(bf_total * other_per_bf)
    local flat     = round2(flat_per_job)

    return {
        labor = labor,
        overhead = overhead,
        other = other,
        flat = flat,
        total = round2(labor + overhead + other + flat),
        rates = {
            labor_per_bf = labor_per_bf,
            overhead_per_bf = overhead_per_bf,
            other_per_bf = other_per_bf,
            flat_per_job = flat_per_job,
        }
    }
end

local function is_external_source(name)
    return type(name) == "string" and name ~= "input"
end

local function find_cheapest_external_source(compare_model)
    local best_name, best_total
    for name, t in pairs(compare_model.totals or {}) do
        if is_external_source(name) and type(t) == "table" then
            local total = safe_num(t.total)
            if total and (not best_total or total < best_total) then
                best_name, best_total = name, total
            end
        end
    end
    return best_name, best_total
end

local function build_scenario(compare_model, baseline_name, discount, bf_total, cost_model)
    local revenue = 0

    for _, row in ipairs(compare_model.rows or {}) do
        local offer = row.offers and row.offers[baseline_name]
        if offer and offer.pricing then
            local total = safe_num(offer.pricing.total)
            if total then
                revenue = revenue + total * (1 - discount)
            end
        end
    end

    revenue = round2(revenue)

    local costs  = compute_costs(bf_total, cost_model)
    local profit = round2(revenue - costs.total)

    local bf_price = bf_total > 0 and round2(revenue / bf_total) or 0

    return {
        name = discount == 0
            and ("Match " .. baseline_name)
            or  string.format("%d%% Under %s", discount * 100, baseline_name),

        baseline = baseline_name,
        discount = discount,

        job = {
            bf_total = bf_total,
            revenue  = revenue,
            bf_price = bf_price,
            costs    = costs,
            profit   = {
                dollars  = profit,
                pct      = revenue > 0 and (profit / revenue) * 100 or nil,
                negative = profit < 0,
            },
        },
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Model.build(compare_model, cost_model, strategy)
    assert(type(compare_model) == "table", "compare_model required")
    assert(type(cost_model) == "table", "cost_model required")

    strategy = strategy or {}
    local discounts = strategy.discounts or { 0.00, 0.05, 0.10 }

    local baseline_name = find_cheapest_external_source(compare_model)
    if not baseline_name then
        error("[price_suggestion] no external sources available", 2)
    end

    local bf_total = compute_job_bf_total(compare_model)

    local scenarios = {}
    for _, d in ipairs(discounts) do
        scenarios[#scenarios + 1] =
            build_scenario(compare_model, baseline_name, d, bf_total, cost_model)
    end

    return {
        baseline = baseline_name,
        bf_total = bf_total,
        cost_model = cost_model,
        scenarios = scenarios,
    }
end

return Model
