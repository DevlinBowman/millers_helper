-- core/domain/pricing/strategies/cost_model.lua

local PricingModel = require("core.model.pricing.controller")

local CostModel = {}

local function round2(x)
    return math.floor((x or 0) * 100 + 0.5) / 100
end

local function safe_number(x, default)
    if type(x) == "number" then return x end
    return default
end

local function cost_floor_per_bf(allocations_meta, profile)
    local base_cost = safe_number(allocations_meta.cost_per_bf, 0)
    local overhead  = safe_number(profile.overhead_per_bf, 0)
    return base_cost + overhead
end

local function apply_markup(cost_floor, profile)
    local markup_pct = safe_number(profile.base_markup_pct, 0) / 100
    local raw_markup = cost_floor * markup_pct
    local min_margin = safe_number(profile.min_margin_per_bf, 0)

    local final_markup = raw_markup
    if final_markup < min_margin then
        final_markup = min_margin
    end

    return {
        cost_floor_per_bf   = cost_floor,
        raw_markup          = raw_markup,
        final_markup        = final_markup,
        final_price_per_bf  = cost_floor + final_markup,
    }
end

function CostModel.run(env)
    local profile = env.profile
    assert(type(profile) == "table", "[pricing.cost_model] profile required")

    local board_items =
        PricingModel.envelope_items(env.boards, "boards", "boards")

    local _, allocations_meta =
        PricingModel.envelope_items(env.allocations, "allocations", "allocations")

    assert(type(allocations_meta.cost_per_bf) == "number",
        "[pricing.cost_model] allocations.meta.cost_per_bf required")

    local floor = cost_floor_per_bf(allocations_meta, profile)

    local per_board = {}

    for i, b in ipairs(board_items) do
        local pricing = apply_markup(floor, profile)

        per_board[i] = {
            label = b.label,

            math = {
                cost_floor_per_bf   = round2(pricing.cost_floor_per_bf),
                final_price_per_bf  = round2(pricing.final_price_per_bf),
            },

            suggested_price_per_bf     = round2(pricing.final_price_per_bf),
            recommended_price_per_bf   = round2(pricing.final_price_per_bf),
            recommendation_mode        = "cost_model",
        }
    end

    return {
        basis      = "cost_model",
        profile_id = profile.profile_id,
        per_board  = per_board,
        meta = {
            allocations_cost_per_bf = allocations_meta.cost_per_bf,
            overhead_per_bf         = profile.overhead_per_bf,
        },
        opts = env.opts or {},
    }
end

return CostModel
