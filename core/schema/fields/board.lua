-- core/meta/board.lua
--
-- Board Meta Definition Space
--
-- Authoritative semantic definition of canonical board fields.
-- No value universe definitions.
-- Pure structural + semantic governance.

local Board = {}

---@type table<string, FieldRecord>
Board.FIELD = {

    ------------------------------------------------------------
    -- Dimensions
    ------------------------------------------------------------

    BASE_H = {
        kind        = "field",
        domain      = "board",
        name        = "base_h",
        type        = "number",
        required    = true,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "inches",
        groups      = { "dimensions", "physical", "face" },
        description = "Declared board height (nominal or finished).",
    },

    BASE_W = {
        kind        = "field",
        domain      = "board",
        name        = "base_w",
        type        = "number",
        required    = true,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "inches",
        groups      = { "dimensions", "physical", "face" },
        description = "Declared board width (nominal or finished).",
    },

    LENGTH = {
        kind        = "field",
        domain      = "board",
        name        = "l",
        type        = "number",
        required    = true,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "feet",
        groups      = { "dimensions", "physical" },
        aliases     = { "length" },
        description = "Board length in feet.",
    },

    COUNT = {
        kind        = "field",
        domain      = "board",
        name        = "ct",
        type        = "number",
        required    = false,
        default     = 1,
        authority   = "authoritative",
        mutable     = true,
        unit        = "count",
        groups      = { },
        aliases     = { "count" },
        description = "Quantity of identical boards in batch.",
    },

    ------------------------------------------------------------
    -- Classification (Closed-World Symbol Fields)
    ------------------------------------------------------------

    GRADE = {
        kind        = "field",
        domain      = "board",
        name        = "grade",
        type        = "symbol",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        reference   = "board.grade",
        groups      = { "classification" },
        description = "Material grade classification.",
    },

    SPECIES = {
        kind        = "field",
        domain      = "board",
        name        = "species",
        type        = "symbol",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        reference   = "board.species",
        groups      = { "classification" },
        description = "Wood species identifier.",
    },

    MOISTURE = {
        kind        = "field",
        domain      = "board",
        name        = "moisture",
        type        = "symbol",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        reference   = "board.moisture",
        groups      = { "classification" },
        description = "Moisture condition.",
    },

    SURFACE = {
        kind        = "field",
        domain      = "board",
        name        = "surface",
        type        = "symbol",
        required    = false,
        default     = "RO",
        authority   = "authoritative",
        mutable     = true,
        reference   = "board.surface",
        groups      = { "classification", "finish" },
        description = "Surface preparation level.",
    },

    TAG = {
        kind        = "field",
        domain      = "board",
        name        = "tag",
        type        = "symbol",
        required    = false,
        default     = "n",
        authority   = "authoritative",
        mutable     = true,
        reference   = "board.tag",
        groups      = { "classification" },
        description = "Dimension interpretation flag.",
    },

    ------------------------------------------------------------
    -- Derived Metrics
    ------------------------------------------------------------

    BF_EA = {
        kind        = "field",
        domain      = "board",
        name        = "bf_ea",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "derived",
        mutable     = false,
        unit        = "board_feet",
        precision   = 3,
        groups      = { "metrics", "volume" },
        description = "Board feet per individual board.",
    },

    BF_BATCH = {
        kind        = "field",
        domain      = "board",
        name        = "bf_batch",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "derived",
        mutable     = false,
        unit        = "board_feet",
        precision   = 3,
        groups      = { "metrics", "volume" },
        description = "Total board feet for the batch.",
    },

    BF_PER_LF = {
        kind        = "field",
        domain      = "board",
        name        = "bf_per_lf",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "derived",
        mutable     = false,
        unit        = "board_feet_per_linear_foot",
        precision   = 4,
        groups      = { "metrics", "volume" },
        description = "Board feet per linear foot.",
    },

    ------------------------------------------------------------
    -- Pricing
    ------------------------------------------------------------

    BF_PRICE = {
        kind        = "field",
        domain      = "board",
        name        = "bf_price",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "usd_per_board_foot",
        precision   = 2,
        groups      = { "pricing" },
        description = "Price per board foot (USD).",
    },

    EA_PRICE = {
        kind        = "field",
        domain      = "board",
        name        = "ea_price",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "usd_each",
        precision   = 2,
        groups      = { "pricing" },
        description = "Price per individual board (USD).",
    },

    LF_PRICE = {
        kind        = "field",
        domain      = "board",
        name        = "lf_price",
        type        = "number",
        required    = false,
        default     = nil,
        authority   = "authoritative",
        mutable     = true,
        unit        = "usd_per_linear_foot",
        precision   = 2,
        groups      = { "pricing" },
        description = "Price per linear foot (USD).",
    },

}

return Board
