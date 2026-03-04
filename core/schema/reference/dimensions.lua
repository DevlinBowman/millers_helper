-- core/schema/reference/dimension.lua
--
-- Engineering reference dataset for dimensional lumber.
-- Not part of semantic validation.
-- Used by normalization and enrichment systems only.

local Dimension = {}

------------------------------------------------------------
-- Nominal → Delivered (S4S actual size)
------------------------------------------------------------

Dimension.nominal_to_actual = {
    [1]  = 0.75,
    [2]  = 1.50,
    [3]  = 2.50,
    [4]  = 3.50,
    [6]  = 5.50,
    [8]  = 7.25,
    [10] = 9.25,
    [12] = 11.25,
}

------------------------------------------------------------
-- Common nominal sets
------------------------------------------------------------

Dimension.common = {
    thickness = { 1, 2, 4, 6, 8, 10, 12 },
    width     = { 1, 2, 4, 6, 8, 10, 12 },
    length_ft = { 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20 },
}

------------------------------------------------------------
-- Planing removal (total across faces)
------------------------------------------------------------

Dimension.planing_allowance = {
    [1]  = 0.1875,
    [2]  = 0.1875,
    [3]  = 0.1875,
    [4]  = 0.1875,
    [6]  = 0.25,
    [8]  = 0.25,
    [10] = 0.25,
    [12] = 0.25,
}

------------------------------------------------------------
-- Retail length overage (inches)
------------------------------------------------------------

Dimension.length_allowance = {
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

------------------------------------------------------------
-- Shrinkage (green → dry)
------------------------------------------------------------

Dimension.shrinkage = {
    redwood = {
        thickness = 0.013,
        width     = 0.029,
        length    = 0.002,
    },
    generic_softwood = {
        thickness = 0.015,
        width     = 0.030,
        length    = 0.002,
    },
}

return Dimension
