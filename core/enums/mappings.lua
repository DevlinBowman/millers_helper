-- enums/mappings.lua
-- Dimensional lumber reference mappings
-- US softwood / redwood oriented
--
-- PURPOSE:
--   Canonical DATA for:
--     • advertised (nominal) dimensions
--     • delivered retail expectations
--     • rough stock derivation inputs
--     • planing, trimming, and shrinkage allowances
--
-- DESIGN:
--   • DATA ONLY (no logic)
--   • Retail-realistic baselines
--   • Explicit physical meaning
--   • Cross-reference friendly
--   • Stable over time

local M = {}

----------------------------------------------------------------
-- UNITS
----------------------------------------------------------------

M.units = {
    thickness = "inches",
    width     = "inches",
    length_ft = "feet",
    length_in = "inches",
}

----------------------------------------------------------------
-- STANDARD ADVERTISED DIMENSIONS (PROJECT-NOMINAL)
----------------------------------------------------------------
-- Nominal in THIS PROJECT = delivered, surfaced size (customer contract)

M.common_dimensions = {
    thickness = { 1, 2, 4, 6, 8, 10, 12 },
    width     = { 1, 2, 4, 6, 8, 10, 12 },
    length_ft = { 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20 },
}

----------------------------------------------------------------
-- FULL → NOMINAL (SURFACED, DELIVERED)
----------------------------------------------------------------
-- Full (rough target size) → Nominal (finished retail size)

M.full_to_nominal = {
    [1]  = 0.75,
    [2]  = 1.50,
    [3]  = 2.50,
    [4]  = 3.50,
    [6]  = 5.50,
    [8]  = 7.25,
    [10] = 9.25,
    [12] = 11.25,
}

----------------------------------------------------------------
-- PLANING / SURFACING ALLOWANCE (TOTAL REMOVAL)
----------------------------------------------------------------
-- Total material removed across BOTH faces to achieve smooth S4S stock

M.planing_allowance = {
    -- full dimension : total thickness removed (in)
    [1]  = 0.1875,  -- 3/16"
    [2]  = 0.1875,
    [3]  = 0.1875,
    [4]  = 0.1875,
    [6]  = 0.25,
    [8]  = 0.25,
    [10] = 0.25,
    [12] = 0.25,
}

----------------------------------------------------------------
-- RETAIL DELIVERED LENGTH ALLOWANCE
----------------------------------------------------------------
-- Typical big-box / retail yard overlength
-- Dry, S4S, end-trimmed stock

M.length_allowance = {
    -- nominal_ft : extra_length_in
    [5]  = 0.25,
    [6]  = 0.25,
    [7]  = 0.25,
    [8]  = 0.25,
    [9]  = 0.375,
    [10] = 0.50,
    [12] = 0.50,
    [14] = 0.75,
    [16] = 0.75,
    [18] = 1.00,
    [20] = 1.00,
}

----------------------------------------------------------------
-- WOOD SHRINKAGE COEFFICIENTS (GREEN → DRY)
----------------------------------------------------------------
-- Percent shrinkage from green to ~12% MC
-- Used as inverse factors when solving for green rough dimensions

M.shrinkage = {
    -- species defaults (conservative)
    redwood = {
        thickness = 0.013,  -- radial ≈ 1.3%
        width     = 0.029,  -- tangential ≈ 2.9%
        length    = 0.002,  -- longitudinal ≈ negligible
    },

    generic_softwood = {
        thickness = 0.015,
        width     = 0.030,
        length    = 0.002,
    },
}

----------------------------------------------------------------
-- MOISTURE STATES (REFERENCE)
----------------------------------------------------------------
-- For future expansion / validation

M.moisture_states = {
    green = {
        description = "Above fiber saturation (~30% MC)",
        shrinkage_active = false,
    },
    drying = {
        description = "Below fiber saturation, shrinking",
        shrinkage_active = true,
    },
    dry = {
        description = "In-service lumber (~10–12% MC)",
        shrinkage_active = false,
    },
}

----------------------------------------------------------------
-- NOTES / INTERPRETATION
----------------------------------------------------------------

M.notes = {
    nominal = "Nominal = expected alternative dimensions as used in the market alternative to the used label",
    full    = "Full = dimension as described in a label",
    planing = "Planing allowance is TOTAL removal across both faces",
    shrink  = "Shrinkage applies when drying below fiber saturation",
    length  = "Retail overlength is minimal; milling requires more",
    warning = "All values are baselines; real stock varies by mill, grade, and cut",
}

----------------------------------------------------------------
-- DESIGN INTENT
----------------------------------------------------------------
-- This file intentionally DOES NOT encode transformations.
--
-- Example usage elsewhere:
--
--   1) Resolve nominal delivered size (full_to_nominal)
--   2) Add planing allowance → dry rough
--   3) Invert shrinkage → green rough
--   4) Add trim allowance → green rough length
--
-- This separation prevents silent volume errors.

return M
