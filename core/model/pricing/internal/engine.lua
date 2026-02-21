-- core/model/pricing/internal/engine.lua
--
-- Pure pricing suggestion engine.
-- Consumes compare_model (NOT raw vendor boards).
--
-- Flow:
--   1) cost floor
--   2) nonlinear factor multiplier
--   3) read vendor pricing from compare_model
--   4) discount ladder per board
--   5) recommendation = max(cost_model, market_target)

local Curve = require("core.model.pricing.internal.curve")
local Grade = require("core.enums.grades")

local Engine = {}

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

local function round2(x)
    return math.floor((x or 0) * 100 + 0.5) / 100
end

local function safe_number(x, default)
    if type(x) == "number" then return x end
    return default
end

local function min_face(board)
    local h = board.h or board.base_h
    local w = board.w or board.base_w
    if type(h) ~= "number" or type(w) ~= "number" then return nil end
    return (h < w) and h or w
end

local function area(board)
    local h = board.h or board.base_h
    local w = board.w or board.base_w
    if type(h) ~= "number" or type(w) ~= "number" then return nil end
    return h * w
end

local function length_ft(board)
    return type(board.l) == "number" and board.l or nil
end

----------------------------------------------------------------
-- Cost Floor
----------------------------------------------------------------

local function cost_floor_per_bf(cost_surface, profile)
    local base_cost = safe_number(cost_surface.cost_per_bf, 0)
    local overhead  = safe_number(profile.overhead_per_bf, 0)
    return base_cost + overhead
end

local function apply_markup(cost_floor, profile, multiplier)

    local markup_pct = safe_number(profile.base_markup_pct, 0) / 100
    local raw_markup = cost_floor * markup_pct * multiplier

    local min_margin = safe_number(profile.min_margin_per_bf, 0)

    local final_markup = raw_markup
    if final_markup < min_margin then
        final_markup = min_margin
    end

    return {
        raw_markup = raw_markup,
        final_markup = final_markup,
        final_price_per_bf = cost_floor + final_markup,
    }
end

----------------------------------------------------------------
-- Factor Resolution
----------------------------------------------------------------

local function resolve_grade(grade_key)

    local g = Grade.get(grade_key)

    if not g or g.kind ~= "grade" then
        return { factor = 1.0, source = "grade_not_found" }
    end

    return {
        factor = g.value or 1.0,
        source = "enum_value",
        grade_value = g.value,
        zone = g.zone,
        grain = g.grain,
    }
end

local function resolve_piecewise(curve, value)

    if type(curve) ~= "table" or value == nil then
        return { factor = 1.0 }
    end

    return Curve.match_piecewise(curve, value)
end

local function resolve_custom(profile, board, opts)

    local custom = profile.custom_order
    if type(custom) ~= "table" or custom.enabled ~= true then
        return {
            waste = { factor = 1.0 },
            rush  = { factor = 1.0 },
            small = { factor = 1.0 },
        }
    end

    opts = opts or {}

    local waste = resolve_piecewise(custom.waste_curve, safe_number(opts.waste_ratio, 0))
    local rush  = resolve_piecewise(custom.rush_curve,  safe_number(opts.rush_level, 0))

    local minf = min_face(board)
    if minf == nil then minf = math.huge end

    local small = resolve_piecewise(custom.small_piece_curve, minf)

    return {
        waste = waste,
        rush  = rush,
        small = small,
    }
end

local function board_factors(profile, board, opts)

    local grade  = resolve_grade(board.grade)
    local size   = resolve_piecewise(profile.size_curve,   area(board) or 0)
    local length = resolve_piecewise(profile.length_curve, length_ft(board) or 0)
    local custom = resolve_custom(profile, board, opts)

    local total =
        (grade.factor or 1.0)
        * (size.factor or 1.0)
        * (length.factor or 1.0)
        * (custom.waste.factor or 1.0)
        * (custom.rush.factor or 1.0)
        * (custom.small.factor or 1.0)

    return {
        grade = grade,
        size = size,
        length = length,
        custom = custom,
        multiplier_total = total,
    }
end

----------------------------------------------------------------
-- Market Extraction (from compare_model)
----------------------------------------------------------------

local function extract_market_from_compare(compare_model, index, discount_points, requested_discount)

    if not compare_model
    or type(compare_model.rows) ~= "table"
    or not compare_model.rows[index] then
        return nil
    end

    local row = compare_model.rows[index]

    for source_name, offer in pairs(row.offers or {}) do

        if source_name ~= "input"
        and offer.pricing
        and type(offer.pricing.bf) == "number" then

            local retail_bf = offer.pricing.bf

            local ladder = {}
            for _, d in ipairs(discount_points) do
                ladder[d] = retail_bf * (1 - d / 100)
            end

            return {
                source = source_name,
                match  = offer.meta and offer.meta.label,
                signal = offer.meta and offer.meta.match_type,
                retail_bf_price = retail_bf,
                ladder = ladder,
                requested_target = ladder[requested_discount],
            }
        end
    end

    return nil
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Engine.suggest(boards, cost_surface, profile, compare_model, opts)

    opts = opts or {}

    local floor = cost_floor_per_bf(cost_surface, profile)
    local discount_points = profile.retail_discount_points or {0,10,20}
    local requested_discount = safe_number(opts.market_target_discount, 15)

    local per_board = {}

    for i, b in ipairs(boards) do

        local factors = board_factors(profile, b, opts)
        local markup  = apply_markup(floor, profile, factors.multiplier_total)

        local cost_model_bf = markup.final_price_per_bf

        local market = extract_market_from_compare(
            compare_model,
            i,
            discount_points,
            requested_discount
        )

        local recommended = cost_model_bf
        local mode = "cost_model"

        if market and type(market.requested_target) == "number" then
            recommended = math.max(cost_model_bf, market.requested_target)
            mode = "max(cost, market)"
        end

        per_board[i] = {
            label = b.label,

            factors = factors,

            math = {
                cost_floor_per_bf = floor,
                final_price_per_bf = cost_model_bf,
            },

            market = market,

            suggested_price_per_bf   = round2(cost_model_bf),
            recommended_price_per_bf = round2(recommended),
            recommendation_mode      = mode,
        }
    end

    return {
        profile_id = profile.profile_id,
        cost_floor_per_bf = round2(floor),
        per_board = per_board,
        opts = opts,
    }
end

return Engine
