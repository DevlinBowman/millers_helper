-- core/model/pricing/internal/presets.lua
--
-- Static pricing profile presets (nonlinear policy knobs).

local Presets = {}

Presets.default = {
    profile_id  = "default",
    description = "Default pricing policy: cost floor + nonlinear scarcity + custom waste",

    overhead_per_bf    = 0.35,
    base_markup_pct    = 25,
    min_margin_per_bf  = 0.25,

    ----------------------------------------------------------------
    -- Grade Curve (map style)
    -- factor multiplies the MARKUP portion (not raw cost)
    ----------------------------------------------------------------

    grade_curve = {
        ["FAS"]     = 1.45,
        ["SEL"]     = 1.35,
        ["1C"]      = 1.20,
        ["2C"]      = 1.00,
        ["3C"]      = 0.85,
        ["RUSTIC"]  = 0.90,
        ["DEFAULT"] = 1.00,
    },

    ----------------------------------------------------------------
    -- Size scarcity: based on cross-section area (h * w)
    ----------------------------------------------------------------

    size_curve = {
        { max = 4,         factor = 1.05 },
        { max = 16,        factor = 1.12 },
        { max = 36,        factor = 1.25 },
        { max = 64,        factor = 1.45 },
        { max = math.huge, factor = 1.70 },
    },

    ----------------------------------------------------------------
    -- Length scarcity: based on length in feet
    ----------------------------------------------------------------

    length_curve = {
        { max = 6,         factor = 1.00 },
        { max = 8,         factor = 1.08 },
        { max = 10,        factor = 1.18 },
        { max = 12,        factor = 1.32 },
        { max = 16,        factor = 1.55 },
        { max = math.huge, factor = 1.75 },
    },

    ----------------------------------------------------------------
    -- Custom order nonlinear adjustments
    ----------------------------------------------------------------

    custom_order = {
        enabled = true,

        waste_curve = {
            { max = 0.05,       factor = 1.00 },
            { max = 0.10,       factor = 1.08 },
            { max = 0.20,       factor = 1.20 },
            { max = 0.35,       factor = 1.40 },
            { max = math.huge,  factor = 1.70 },
        },

        rush_curve = {
            { max = 0.0,        factor = 1.00 },
            { max = 1.0,        factor = 1.25 },
            { max = math.huge,  factor = 1.60 },
        },

        small_piece_curve = {
            { max = 2.0,        factor = 1.20 },
            { max = math.huge,  factor = 1.00 },
        },
    },

    ----------------------------------------------------------------
    -- Retail discount ladder
    ----------------------------------------------------------------

    retail_discount_points = { 0, 5, 10, 15, 20, 25, 30 },
}

return Presets
