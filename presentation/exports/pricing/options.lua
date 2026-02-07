-- presentation/exports/pricing/options.lua
--
-- Pricing option generator (v1).
--
-- Input:
--   • compare_model (output of presentation.exports.compare.model.build)
--   • cost_model   (explicit business truth)
--   • strategy     (baseline + discounts)
--
-- Output:
--   • scenarios array with revenue/cost/profit impact
--   • printable, fixed-width decision table
--
-- Notes (v1):
--   • Baseline retailer = cheapest external source by compare_model.totals[*].total
--   • Discounts are applied per-piece (implemented as scalar on ea/total)
--   • Negative profit is allowed but flagged
--   • Missing baseline per-board offers: fallback to next-cheapest available offer for that board
--     (and flagged in scenario diagnostics)
--   • No yield loss / true-dimension upcharges / reprocessing / grade premiums / dynamic curves

local M = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function round2(n)
    return math.floor((tonumber(n) or 0) * 100 + 0.5) / 100
end

local function safe_num(n)
    n = tonumber(n)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then return nil end
    return n
end

local function money(n)
    n = safe_num(n)
    if n == nil then return "-" end
    return string.format("$%.2f", n)
end

local function pct(n)
    n = safe_num(n)
    if n == nil then return "—" end
    local sign = n > 0 and "+" or ""
    return string.format("%s%.1f%%", sign, n)
end

local function commas_int(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local out = {}
    while #s > 3 do
        out[#out + 1] = s:sub(-3)
        s = s:sub(1, -4)
    end
    out[#out + 1] = s
    local rev = {}
    for i = #out, 1, -1 do rev[#rev + 1] = out[i] end
    return table.concat(rev, ",")
end

local function fmt_bf(n)
    n = safe_num(n)
    if n == nil then return "0.00" end
    return string.format("%.2f", n)
end

local function ljust(s, w)
    s = tostring(s or "")
    if #s > w then return s:sub(1, w) end
    return string.format("%-" .. w .. "s", s)
end

local function rjust(s, w)
    s = tostring(s or "")
    if #s > w then return s:sub(1, w) end
    return string.format("%" .. w .. "s", s)
end

local function basename(path)
    path = tostring(path or "")
    local name = path:match("([^/]+)$") or path
    return name:gsub("%.txt$", "")
end

local function display_source(src)
    if src == "input" then return "our price" end
    return basename(src)
end

local function is_external_source(name)
    return type(name) == "string" and name ~= "input"
end

local function compute_job_bf_total(compare_model)
    local bf_total = 0
    for _, row in ipairs(compare_model.rows or {}) do
        local ob = row.order_board or {}
        local p = ob.physical or {}
        local bf_batch = safe_num(p.bf_batch)
        if bf_batch == nil then
            local bf_ea = safe_num(p.bf_ea) or 0
            local ct = safe_num(p.ct) or 1
            bf_batch = bf_ea * ct
        end
        bf_total = bf_total + (bf_batch or 0)
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

    local total = round2(labor + overhead + other + flat)

    return {
        labor = labor,
        overhead = overhead,
        other = other,
        flat = flat,
        total = total,
        rates = {
            labor_per_bf = labor_per_bf,
            overhead_per_bf = overhead_per_bf,
            other_per_bf = other_per_bf,
            flat_per_job = flat_per_job,
        }
    }
end

local function find_cheapest_external_source(compare_model)
    local best_name, best_total

    for name, t in pairs(compare_model.totals or {}) do
        if is_external_source(name) and type(t) == "table" then
            local total = safe_num(t.total)
            if total ~= nil then
                if best_total == nil or total < best_total then
                    best_total = total
                    best_name = name
                end
            end
        end
    end

    return best_name, best_total
end

local function find_best_fallback_offer(row, exclude_name)
    -- Choose the cheapest available external offer for this row (by offer.pricing.total).
    local best_name, best_offer, best_total

    for name, offer in pairs((row and row.offers) or {}) do
        if is_external_source(name) and name ~= exclude_name and type(offer) == "table" then
            local pr = offer.pricing or {}
            local total = safe_num(pr.total)
            if total ~= nil then
                if best_total == nil or total < best_total then
                    best_total = total
                    best_name = name
                    best_offer = offer
                end
            end
        end
    end

    return best_name, best_offer
end

local function get_baseline_offer_for_row(row, baseline_name)
    local offers = (row and row.offers) or {}
    local offer = offers[baseline_name]
    if type(offer) == "table" and type(offer.pricing) == "table" then
        local pr = offer.pricing
        local ea = safe_num(pr.ea)
        local total = safe_num(pr.total)
        if ea ~= nil and total ~= nil then
            return baseline_name, offer, false
        end
    end

    -- Fallback: pick next-cheapest external offer for this row
    local fb_name, fb_offer = find_best_fallback_offer(row, baseline_name)
    if fb_offer and type(fb_offer.pricing) == "table" then
        local pr = fb_offer.pricing
        local ea = safe_num(pr.ea)
        local total = safe_num(pr.total)
        if ea ~= nil and total ~= nil then
            return fb_name, fb_offer, true
        end
    end

    return nil, nil, false
end

local function build_scenario(compare_model, baseline_name, discount, bf_total, cost_model)
    local revenue = 0
    local missing_rows = 0
    local fallback_rows = 0

    for _, row in ipairs(compare_model.rows or {}) do
        local src_used, offer, used_fallback = get_baseline_offer_for_row(row, baseline_name)
        if not offer then
            missing_rows = missing_rows + 1
        else
            if used_fallback then fallback_rows = fallback_rows + 1 end

            local pr = offer.pricing or {}
            local ea = safe_num(pr.ea) or 0
            local total = safe_num(pr.total) or 0

            -- Discount is per-piece; scaling total is equivalent because total = ea * ct.
            local discounted_total = total * (1 - discount)
            revenue = revenue + discounted_total
        end
    end

    revenue = round2(revenue)

    local costs = compute_costs(bf_total, cost_model)
    local profit = round2(revenue - costs.total)

    local margin_pct
    if revenue > 0 then
        margin_pct = (profit / revenue) * 100
    end

    local bf_price
    if bf_total > 0 then
        bf_price = revenue / bf_total
    end

    local negative = profit < 0

    local scenario_name
    if discount == 0 then
        scenario_name = "Match " .. display_source(baseline_name)
    else
        scenario_name = string.format("%d%% Under %s", math.floor(discount * 100 + 0.5), display_source(baseline_name))
    end

    return {
        name = scenario_name,
        baseline = baseline_name,
        discount = discount,

        job = {
            bf_total = bf_total,
            revenue = revenue,
            bf_price = round2(bf_price or 0),

            costs = costs,
            profit = {
                dollars = profit,
                pct = margin_pct,
                negative = negative,
            },
        },

        diagnostics = {
            missing_rows = missing_rows,
            fallback_rows = fallback_rows,
        }
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Build pricing scenarios from a compare model.
--- @param compare_model table
--- @param cost_model table
--- @param strategy table|nil { discounts = {0.00,0.05,0.10}, baseline="cheapest" }
--- @return table result
function M.build(compare_model, cost_model, strategy)
    assert(type(compare_model) == "table", "compare_model required")
    assert(type(cost_model) == "table", "cost_model required")

    strategy = strategy or {}
    local discounts = strategy.discounts or { 0.00, 0.05, 0.10 }

    local baseline_name, baseline_total = find_cheapest_external_source(compare_model)
    if not baseline_name then
        error("[pricing.options] no external sources available in compare_model.totals", 2)
    end

    local bf_total = compute_job_bf_total(compare_model)

    local scenarios = {}
    for _, d in ipairs(discounts) do
        scenarios[#scenarios + 1] = build_scenario(compare_model, baseline_name, tonumber(d) or 0, bf_total, cost_model)
    end

    return {
        baseline = {
            source = baseline_name,
            job_total = baseline_total,
        },
        bf_total = bf_total,
        cost_model = cost_model,
        scenarios = scenarios,
    }
end

--- Print a decision table for pricing scenarios.
--- @param result table
function M.print(result)
    assert(type(result) == "table", "result required")

    local baseline = result.baseline or {}
    local bf_total = safe_num(result.bf_total) or 0

    local W = {
        option = 28,
        total = 12,
        perbf = 10,
        cost = 12,
        profit = 12,
        margin = 9,
        flag = 8,
    }

    local function line(ch)
        local width =
            W.option + 1 +
            W.total + 1 +
            W.perbf + 1 +
            W.cost + 1 +
            W.profit + 1 +
            W.margin + 1 +
            W.flag
        print(string.rep(ch, width))
    end

    line("=")
    print("PRICING OPTIONS — MARKET-ALIGNED")
    print("Baseline retailer: " .. display_source(baseline.source))
    print("Job BF total: " .. commas_int(bf_total) .. " bf")
    line("=")

    print(
        ljust("OPTION", W.option) .. " " ..
        rjust("JOB TOTAL", W.total) .. " " ..
        rjust("$/BF", W.perbf) .. " " ..
        rjust("COST", W.cost) .. " " ..
        rjust("PROFIT", W.profit) .. " " ..
        rjust("MARGIN", W.margin) .. " " ..
        ljust("", W.flag)
    )
    line("-")

    -- Keep scenario order as provided (typically match, 5%, 10%)
    for _, sc in ipairs(result.scenarios or {}) do
        local job = sc.job or {}
        local costs = (job.costs and job.costs.total) or 0
        local profit = (job.profit and job.profit.dollars) or 0
        local margin = (job.profit and job.profit.pct) or nil

        local flag = ""
        if job.profit and job.profit.negative then
            flag = "LOSS"
        end

        print(
            ljust(sc.name, W.option) .. " " ..
            rjust(money(job.revenue), W.total) .. " " ..
            rjust(money(job.bf_price), W.perbf) .. " " ..
            rjust(money(costs), W.cost) .. " " ..
            rjust(money(profit), W.profit) .. " " ..
            rjust(pct(margin), W.margin) .. " " ..
            ljust(flag, W.flag)
        )
    end

    line("-")

    -- Diagnostics summary
    local any_missing, any_fallback = 0, 0
    for _, sc in ipairs(result.scenarios or {}) do
        local d = sc.diagnostics or {}
        any_missing = any_missing + (d.missing_rows or 0)
        any_fallback = any_fallback + (d.fallback_rows or 0)
    end

    print("Notes:")
    print("• Costs are labor/overhead/other per-bf + optional flat per-job (no yield loss/reprocessing/true-dim premiums).")
    print("• Retail prices are taken from compare model offers normalized to your board geometry.")
    if any_fallback > 0 then
        print(string.format("• Fallbacks used: %d row(s) across scenarios (baseline missing per-board offer; used next-cheapest available).", any_fallback))
    end
    if any_missing > 0 then
        print(string.format("• Missing pricing: %d row(s) across scenarios (no external offer available for some board(s)).", any_missing))
    end

    line("=")
end

return M
