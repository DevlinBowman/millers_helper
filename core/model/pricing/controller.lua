-- core/model/pricing/controller.lua
--
-- Pricing Model Controller
--
-- Exposes pure pricing math utilities.
-- No domain orchestration.

local Trace    = require("tools.trace.trace")

local Registry = require("core.model.pricing.registry")

local Controller = {}

----------------------------------------------------------------
-- Board Factor Resolution
----------------------------------------------------------------
function Controller.board_factors(profile, board, opts)

    opts = opts or {}

    local size_curve   = profile.size_curve
    local length_curve = profile.length_curve
    local grade_curve  = profile.grade_curve

    local size_factor   = 1.0
    local length_factor = 1.0
    local grade_factor  = 1.0

    local h = board.h or board.base_h
    local w = board.w or board.base_w
    local l = board.l

    ------------------------------------------------
    -- size factor (area)
    ------------------------------------------------

    if size_curve and h and w then
        local area = h * w
        size_factor =
            Controller.curve_match_piecewise(size_curve, area).factor
    end

    ------------------------------------------------
    -- length factor
    ------------------------------------------------

    if length_curve and l then
        length_factor =
            Controller.curve_match_piecewise(length_curve, l).factor
    end

    ------------------------------------------------
    -- grade factor
    ------------------------------------------------

    if grade_curve and board.grade then
        grade_factor =
            Controller.curve_match_map(grade_curve, board.grade).factor
    end

    ------------------------------------------------
    -- custom adjustments
    ------------------------------------------------

    local custom_factor = 1.0
    local custom = profile.custom_order

    if custom and custom.enabled then

        if custom.waste_curve then
            local waste_ratio = opts.waste_ratio or 0

            custom_factor =
                custom_factor *
                Controller.curve_match_piecewise(
                    custom.waste_curve,
                    waste_ratio
                ).factor
        end

        if custom.rush_curve then
            local rush_level = opts.rush_level or 0

            custom_factor =
                custom_factor *
                Controller.curve_match_piecewise(
                    custom.rush_curve,
                    rush_level
                ).factor
        end

        if custom.small_piece_curve then

            local min_face
            if h and w then
                min_face = math.min(h, w)
            end

            if min_face then
                custom_factor =
                    custom_factor *
                    Controller.curve_match_piecewise(
                        custom.small_piece_curve,
                        min_face
                    ).factor
            end
        end
    end

    ------------------------------------------------
    -- final multiplier
    ------------------------------------------------

    local multiplier_total =
        grade_factor *
        size_factor *
        length_factor *
        custom_factor

    return {
        grade_factor  = grade_factor,
        size_factor   = size_factor,
        length_factor = length_factor,
        custom_factor = custom_factor,
        multiplier_total = multiplier_total
    }
end

----------------------------------------------------------------
-- Profile Builder
----------------------------------------------------------------

function Controller.profile_build(profile_id)

    Trace.contract_enter("core.model.pricing.controller.profile_build")

    assert(type(profile_id) == "string", "profile_id required")

    local preset = Registry.presets[profile_id]
    assert(preset, "unknown pricing profile: " .. profile_id)

    local resolved =
        Registry.resolve.run(preset, Registry.presets)

    local normalized =
        Registry.schema.normalize_profile(resolved)

    Registry.validate.run(normalized, Registry.schema)

    Trace.contract_leave()

    return normalized
end

----------------------------------------------------------------
-- Curve utilities
----------------------------------------------------------------

function Controller.curve_match_piecewise(curve, value)
    return Registry.curve.match_piecewise(curve, value)
end

function Controller.curve_match_map(map, key)
    return Registry.curve.match_map(map, key)
end

----------------------------------------------------------------
-- Envelope helpers
----------------------------------------------------------------

function Controller.envelope_items(env, expected_kind, label)
    return Registry.envelope.items(env, expected_kind, label)
end

function Controller.envelope_meta(env, expected_kind, label)
    return Registry.envelope.meta(env, expected_kind, label)
end

return Controller
