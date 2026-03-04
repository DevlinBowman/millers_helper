-- core/values/board/moisture.lua
--
-- Moisture state classifications.

local Moisture = {}

---@type StandardRecord[]
Moisture.VALUE = {

    GR = {
        kind = "value",
        domain = "board.moisture",
        name = "GR",
        type = "symbol",
        rank = 1,
        shrinkage_active = false,
        description = "Green (unseasoned) lumber.",
        aliases = { "green" },
    },

    AD = {
        kind = "value",
        domain = "board.moisture",
        name = "AD",
        type = "symbol",
        rank = 2,
        shrinkage_active = false,
        description = "Air dried lumber.",
        aliases = { "air_dry" },
    },

    KD = {
        kind = "value",
        domain = "board.moisture",
        name = "KD",
        type = "symbol",
        rank = 3,
        shrinkage_active = false,
        description = "Kiln dried lumber.",
        aliases = { "kd", "kiln_dried" },
    },

}

return Moisture
