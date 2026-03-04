-- core/values/board/species.lua
--
-- Canonical species classifications.

local Species = {}

---@type StandardRecord[]
Species.VALUE = {

    RW = {
        kind = "value",
        domain = "board.species",
        name = "RW",
        type = "symbol",
        description = "Coastal Redwood (Sequoia sempervirens).",
        aliases = { "redwood" },
    },

    DF = {
        kind = "value",
        domain = "board.species",
        name = "DF",
        type = "symbol",
        description = "Douglas Fir.",
        aliases = { "douglas_fir", "fir" },
    },

    CD = {
        kind = "value",
        domain = "board.species",
        name = "CD",
        type = "symbol",
        description = "Cedar species.",
        aliases = { "cedar" },
    },

    PN = {
        kind = "value",
        domain = "board.species",
        name = "PN",
        type = "symbol",
        description = "General Pine classification.",
        aliases = { "pine" },
    },

    HF = {
        kind = "value",
        domain = "board.species",
        name = "HF",
        type = "symbol",
        description = "Hem-Fir structural grouping.",
        aliases = { "hem_fir" },
    },

}

return Species
