-- core/domain/enrichment/internal/enums/board.lua
--
-- Canonical board enums.
-- Used by enrichment + completeness.
-- Each entry is self-describing:
--   kind        = "key" | "value"
--   domain      = logical grouping
--   value       = canonical string
--   description = semantic meaning

local BoardEnums = {}

----------------------------------------------------------------
-- Canonical Keys
----------------------------------------------------------------

BoardEnums.KEYS = {

    HEIGHT = {
        kind = "key",
        domain = "board",
        value = "base_h",
        description = "Declared board height (nominal or finished depending on tag).",
    },

    WIDTH = {
        kind = "key",
        domain = "board",
        value = "base_w",
        description = "Declared board width (nominal or finished depending on tag).",
    },

    LENGTH = {
        kind = "key",
        domain = "board",
        value = "l",
        description = "Board length in feet.",
    },

    COUNT = {
        kind = "key",
        domain = "board",
        value = "ct",
        description = "Quantity of identical boards in batch.",
    },

    GRADE = {
        kind = "key",
        domain = "board",
        value = "grade",
        description = "Material grade classification.",
    },

    SPECIES = {
        kind = "key",
        domain = "board",
        value = "species",
        description = "Wood species identifier.",
    },

    MOISTURE = {
        kind = "key",
        domain = "board",
        value = "moisture",
        description = "Moisture condition (e.g. green, kiln-dried).",
    },

    SURFACE = {
        kind = "key",
        domain = "board",
        value = "surface",
        description = "Surface preparation level (rough, s2s, s4s).",
    },

    TAG = {
        kind = "key",
        domain = "board",
        value = "tag",
        description = "Dimension interpretation flag (nominal, finished, custom).",
    },

    BF_EA = {
        kind = "key",
        domain = "board",
        value = "bf_ea",
        description = "Board feet per individual board.",
    },

    BF_BATCH = {
        kind = "key",
        domain = "board",
        value = "bf_batch",
        description = "Total board feet for the batch (bf_ea * count).",
    },

    BF_PER_LF = {
        kind = "key",
        domain = "board",
        value = "bf_per_lf",
        description = "Board feet per linear foot.",
    },

    BF_PRICE = {
        kind = "key",
        domain = "board.pricing",
        value = "bf_price",
        description = "Price per board foot.",
    },

    EA_PRICE = {
        kind = "key",
        domain = "board.pricing",
        value = "ea_price",
        description = "Price per individual board.",
    },

    LF_PRICE = {
        kind = "key",
        domain = "board.pricing",
        value = "lf_price",
        description = "Price per linear foot.",
    },
}

----------------------------------------------------------------
-- Tag Values
----------------------------------------------------------------

BoardEnums.TAG = {

    NOMINAL = {
        kind = "value",
        domain = "board.tag",
        value = "n",
        description = "Dimensions represent nominal (pre-surfaced) size.",
    },

    FINISHED = {
        kind = "value",
        domain = "board.tag",
        value = "f",
        description = "Dimensions represent finished (post-surfaced) size.",
    },

    CUSTOM = {
        kind = "value",
        domain = "board.tag",
        value = "c",
        description = "Custom dimension interpretation.",
    },
}

----------------------------------------------------------------
-- Surface Values
----------------------------------------------------------------

BoardEnums.SURFACE = {

    ROUGH = {
        kind = "value",
        domain = "board.surface",
        value = "rough",
        description = "No surfacing applied.",
    },

    S2S = {
        kind = "value",
        domain = "board.surface",
        value = "s2s",
        description = "Surfaced on two sides.",
    },

    S4S = {
        kind = "value",
        domain = "board.surface",
        value = "s4s",
        description = "Surfaced on four sides.",
    },
}

----------------------------------------------------------------
-- Derived Lookup Sets
----------------------------------------------------------------

BoardEnums.TAG_SET = {}
for _, def in pairs(BoardEnums.TAG) do
    BoardEnums.TAG_SET[def.value] = true
end

BoardEnums.SURFACE_SET = {}
for _, def in pairs(BoardEnums.SURFACE) do
    BoardEnums.SURFACE_SET[def.value] = true
end

return BoardEnums
