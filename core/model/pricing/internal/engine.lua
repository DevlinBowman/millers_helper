-- core/model/pricing/internal/engine.lua
--
-- Pure pricing suggestion engine:
--   1) cost floor from cost_surface + nonlinear adjustments
--   2) retail comparison ladder from matches (optional)
--   3) recommend max(cost_floor, market_target)

local Engine = {}

local function round2(x) return math.floor((x or 0) * 100 + 0.5) / 100 end

local function piecewise_factor(curve, value)
    if type(curve) ~= "table" then return 1.0 end
    for _, step in ipairs(curve) do
        if value <= step.max then return step.factor end
    end
    return 1.0
end

local function grade_factor(map, grade)
    if type(map) ~= "table" then return 1.0 end
    if grade ~= nil and map[grade] ~= nil then return map[grade] end
    return map.DEFAULT or 1.0
end

local function min_face(board)
    local h = board.h or board.base_h
    local w = board.w or board.base_w
    if type(h) ~= "number" or type(w) ~= "number" then return nil end
    if h < w then return h end
    return w
end

local function area(board)
    local h = board.h or board.base_h
    local w = board.w or board.base_w
    if type(h) ~= "number" or type(w) ~= "number" then return nil end
    return h * w
end

local function length_ft(board)
    local l = board.l
    if type(l) ~= "number" then return nil end
    -- your l appears to be feet already; if inches, adjust here later
    return l
end

-- waste_ratio: user-supplied or computed upstream; default 0
-- rush_level: user-supplied scalar; default 0
local function compute_custom_factors(profile, board, opts)
    local custom = profile.custom_order
    if type(custom) ~= "table" or custom.enabled ~= true then
        return { waste = 1.0, rush = 1.0, small = 1.0 }
    end

    opts = opts or {}
    local waste_ratio = opts.waste_ratio or 0
    local rush_level  = opts.rush_level or 0

    local waste = piecewise_factor(custom.waste_curve, waste_ratio)
    local rush  = piecewise_factor(custom.rush_curve, rush_level)

    local minf = min_face(board) or math.huge
    local small = piecewise_factor(custom.small_piece_curve, minf)

    return { waste = waste, rush = rush, small = small }
end

local function board_markup_multiplier(profile, board, opts)
    local gf = grade_factor(profile.grade_curve, board.grade)
    local a  = area(board) or 0
    local lf = length_ft(board) or 0

    local sf = piecewise_factor(profile.size_curve, a)
    local lfct = piecewise_factor(profile.length_curve, lf)

    local cf = compute_custom_factors(profile, board, opts)

    -- Multipliers apply to *markup portion*.
    -- Keep it composable.
    return gf * sf * lfct * cf.waste * cf.rush * cf.small
end

local function cost_floor_per_bf(cost_surface, profile)
    local base_cost = cost_surface.cost_per_bf or 0
    local overhead  = profile.overhead_per_bf or 0
    return base_cost + overhead
end

local function apply_markup(cost_floor, profile, multiplier)
    local markup_pct = (profile.base_markup_pct or 0) / 100
    local markup = cost_floor * markup_pct * multiplier

    local min_margin = profile.min_margin_per_bf or 0
    if markup < min_margin then markup = min_margin end

    return cost_floor + markup
end

----------------------------------------------------------------
-- Retail match ingestion (optional)
----------------------------------------------------------------
-- Expected matches input (you control adapter):
-- matches = {
--   items = {
--     { label=string, retail_bf_price=number?, retail_ea_price=number?, bf_ea=number? },
--     ...
--   }
-- }
local function market_ladder(matches, discount_points)
    local out = {
        discounts = {},
        diagnostics = {},
    }

    if type(matches) ~= "table" or type(matches.items) ~= "table" then
        table.insert(out.diagnostics, "no matches provided")
        return out
    end

    discount_points = discount_points or { 0, 10, 20 }

    -- compute average retail bf price over matched items (simple baseline)
    local sum = 0
    local ct  = 0

    for _, item in ipairs(matches.items) do
        local p = item.retail_bf_price
        if type(p) == "number" and p > 0 then
            sum = sum + p
            ct = ct + 1
        end
    end

    if ct == 0 then
        table.insert(out.diagnostics, "matches had no retail_bf_price values")
        return out
    end

    local avg = sum / ct
    out.avg_retail_bf_price = avg

    for _, d in ipairs(discount_points) do
        local factor = 1.0 - (d / 100)
        out.discounts[d] = avg * factor
    end

    return out
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Engine.suggest(boards, cost_surface, profile, matches, opts)
    opts = opts or {}

    local diagnostics = {}

    local floor = cost_floor_per_bf(cost_surface, profile)
    if floor <= 0 then
        table.insert(diagnostics, "cost floor <= 0; check allocations/cost_surface")
    end

    local discount_points = profile.retail_discount_points or { 0, 10, 20 }
    local market = market_ladder(matches, discount_points)

    -- choose a market target point if present
    local market_target_discount = opts.market_target_discount
    if type(market_target_discount) ~= "number" then
        market_target_discount = 15
    end

    local market_target = nil
    if market.discounts and market.discounts[market_target_discount] then
        market_target = market.discounts[market_target_discount]
    else
        -- fallback: pick the closest discount point
        if market.discounts then
            local best_d, best_v
            for d, v in pairs(market.discounts) do
                if best_d == nil or math.abs(d - market_target_discount) < math.abs(best_d - market_target_discount) then
                    best_d, best_v = d, v
                end
            end
            market_target_discount = best_d
            market_target = best_v
        end
    end

    local per_board = {}
    local sum_suggested_bf = 0
    local bf_ct = 0

    for i, b in ipairs(boards) do
        local mult = board_markup_multiplier(profile, b, opts)
        local suggested_bf = apply_markup(floor, profile, mult)

        per_board[i] = {
            label = b.label or b.id or ("board#" .. tostring(i)),
            bf_ea = b.bf_ea,
            bf_batch = b.bf_batch,
            grade = b.grade,
            dims = { h = b.h or b.base_h, w = b.w or b.base_w, l = b.l },
            markup_multiplier = mult,
            cost_floor_per_bf = floor,
            suggested_price_per_bf = round2(suggested_bf),
            suggested_ea_price = (type(b.bf_ea) == "number" and b.bf_ea > 0) and round2(suggested_bf * b.bf_ea) or nil,
        }

        sum_suggested_bf = sum_suggested_bf + suggested_bf
        bf_ct = bf_ct + 1
    end

    local avg_suggested_bf = (bf_ct > 0) and (sum_suggested_bf / bf_ct) or floor

    local recommendation = {
        mode = "cost_floor",
        recommended_price_per_bf = round2(avg_suggested_bf),
        basis = {
            cost_floor_per_bf = round2(floor),
            avg_suggested_bf = round2(avg_suggested_bf),
        }
    }

    if type(market_target) == "number" and market_target > 0 then
        local rec = math.max(avg_suggested_bf, market_target)
        recommendation.mode = "max(cost, market)"
        recommendation.recommended_price_per_bf = round2(rec)
        recommendation.basis.market_target_discount = market_target_discount
        recommendation.basis.market_target_bf = round2(market_target)
    end

    -- attach diagnostics
    for _, d in ipairs(market.diagnostics or {}) do table.insert(diagnostics, "market: " .. d) end

    return {
        profile_id = profile.profile_id,
        recommendation = recommendation,
        market = market,
        cost = {
            cost_floor_per_bf = round2(floor),
            cost_surface = cost_surface,
        },
        per_board = per_board,
        diagnostics = diagnostics,
    }
end

return Engine
