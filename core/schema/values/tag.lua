-- core/standards/tag.lua
--
-- Dimension interpretation flags.
-- Pure canonical value space.

local Tag = {}

---@type StandardRecord[]
Tag.VALUE = {

    NOMINAL = {
        kind        = "value",
        domain      = "board.tag",

        name        = "n",
        type        = "symbol",

        description = "Nominal (pre-surfaced) dimension.",
        aliases     = { "nominal" },
    },

    FULL = {
        kind        = "value",
        domain      = "board.tag",

        name        = "f",
        type        = "symbol",

        description = "Finished (post-surfaced) dimension.",
        aliases     = { "full" },
    },

    CUSTOM = {
        kind        = "value",
        domain      = "board.tag",

        name        = "c",
        type        = "symbol",

        description = "Custom dimension interpretation.",
        aliases     = { "custom" },
    },
}

return Tag
