-- core/schema/values/board/grade.lua
--
-- Canonical lumber grade combinations.
--
-- This file contains ONLY fully-defined grade values.
-- No axis model.
-- No dynamic construction.
-- No printing.
-- No resolvers.
--
-- Pure data for Core registration.

local Grade = {}

---@type StandardRecord[]
Grade.VALUE = {

    ----------------------------------------------------------------
    -- Construction Common (CC)
    ----------------------------------------------------------------
    CC = {
        kind = "value",
        domain = "board.grade",
        name = "CC",
        type = "symbol",
        zone = "common",
        grain = "construction",
        rank = 3,
        multiplier = 1.00,
        description = "Construction Common.",
        aliases = { "cc", "construction_common" },
    },

    ----------------------------------------------------------------
    -- A Common (CA)
    ----------------------------------------------------------------
    CA = {
        kind = "value",
        domain = "board.grade",
        name = "CA",
        type = "symbol",
        zone = "common",
        grain = "a",
        rank = 6,
        multiplier = 2.70,
        description = "A Common.",
        aliases = { "ca", "a_common" },
    },

    ----------------------------------------------------------------
    -- Construction Heart (HC)
    ----------------------------------------------------------------
    HC = {
        kind = "value",
        domain = "board.grade",
        name = "HC",
        type = "symbol",
        zone = "heart",
        grain = "construction",
        rank = 4,
        multiplier = 1.30,
        description = "Construction Heart.",
        aliases = { "hc", "construction_heart" },
    },

    ----------------------------------------------------------------
    -- A Heart (HA)
    ----------------------------------------------------------------
    HA = {
        kind = "value",
        domain = "board.grade",
        name = "HA",
        type = "symbol",
        zone = "heart",
        grain = "a",
        rank = 7,
        multiplier = 3.51,
        description = "A Heart.",
        aliases = { "ha", "clear_heart", "a_heart" },
    },

    ----------------------------------------------------------------
    -- Merchantable Common (MC)
    ----------------------------------------------------------------
    MC = {
        kind = "value",
        domain = "board.grade",
        name = "MC",
        type = "symbol",
        zone = "common",
        grain = "merchantable",
        rank = 2,
        multiplier = 0.75,
        description = "Merchantable Common.",
        aliases = { "mc", "merchantable_common" },
    },

    ----------------------------------------------------------------
    -- Merchantable Heart (MH)
    ----------------------------------------------------------------
    MH = {
        kind = "value",
        domain = "board.grade",
        name = "MH",
        type = "symbol",
        zone = "heart",
        grain = "merchantable",
        rank = 3,
        multiplier = 0.98,
        description = "Merchantable Heart.",
        aliases = { "mh", "merchantable_heart" },
    },

    ----------------------------------------------------------------
    -- Select Common (SC)
    ----------------------------------------------------------------
    SC = {
        kind = "value",
        domain = "board.grade",
        name = "SC",
        type = "symbol",
        zone = "common",
        grain = "select",
        rank = 5,
        multiplier = 1.20,
        description = "Select Common.",
        aliases = { "sc", "select_common" },
    },

    ----------------------------------------------------------------
    -- Select Heart (SH)
    ----------------------------------------------------------------
    SH = {
        kind = "value",
        domain = "board.grade",
        name = "SH",
        type = "symbol",
        zone = "heart",
        grain = "select",
        rank = 6,
        multiplier = 1.56,
        description = "Select Heart.",
        aliases = { "sh", "select_heart" },
    },

    ----------------------------------------------------------------
    -- B Common (BC)
    ----------------------------------------------------------------
    BC = {
        kind = "value",
        domain = "board.grade",
        name = "BC",
        type = "symbol",
        zone = "common",
        grain = "b",
        rank = 6,
        multiplier = 1.55,
        description = "B Common.",
        aliases = { "bc", "b_common" },
    },

    ----------------------------------------------------------------
    -- B Heart (BH)
    ----------------------------------------------------------------
    BH = {
        kind = "value",
        domain = "board.grade",
        name = "BH",
        type = "symbol",
        zone = "heart",
        grain = "b",
        rank = 7,
        multiplier = 2.015,
        description = "B Heart.",
        aliases = { "bh", "b_heart" },
    },

}

return Grade
