-- core/values/board/surface.lua
--
-- Canonical surface preparation classifications.
-- Closed-world value universe.
--
-- Domain: "board.surface"
-- Board fields reference this via: reference = "board.surface"

local Surface = {}

---@type StandardRecord[]
Surface.VALUE = {

    ------------------------------------------------------------
    -- Rough
    ------------------------------------------------------------
    RO = {
        kind = "value",
        domain = "board.surface",
        name = "RO",
        type = "symbol",
        faces = 0,
        edges = 0,
        description = "Rough sawn; unsurfaced faces and edges.",
        aliases = { "rough", "r" },
    },

    ------------------------------------------------------------
    -- Surfaced Two Sides
    ------------------------------------------------------------
    S2 = {
        kind = "value",
        domain = "board.surface",
        name = "S2",
        type = "symbol",
        faces = 2,
        edges = 0,
        description = "Surfaced on two wide faces; edges remain rough.",
        aliases = { "s2s" },
    },

    ------------------------------------------------------------
    -- Surfaced Four Sides
    ------------------------------------------------------------
    S4 = {
        kind = "value",
        domain = "board.surface",
        name = "S4",
        type = "symbol",
        faces = 2,
        edges = 2,
        description = "Surfaced on all four sides; square edges.",
        aliases = { "s4s", "4s" },
    },

    ------------------------------------------------------------
    -- Profiled Surfaces
    ------------------------------------------------------------
    VR = {
        kind = "value",
        domain = "board.surface",
        name = "VR",
        type = "symbol",
        faces = 2,
        edges = 2,
        description = "S4S with V-joint interlocking edge profile.",
        aliases = { "v_rustic", "v-joint" },
    },

    SL = {
        kind = "value",
        domain = "board.surface",
        name = "SL",
        type = "symbol",
        faces = 2,
        edges = 2,
        description = "S4S with rabbeted overlapping shiplap edge profile.",
        aliases = { "shiplap" },
    },

    TG = {
        kind = "value",
        domain = "board.surface",
        name = "TG",
        type = "symbol",
        faces = 2,
        edges = 2,
        description = "S4S with tongue-and-groove interlocking edge profile.",
        aliases = { "tongue_groove", "tng" },
    },

}

return Surface
