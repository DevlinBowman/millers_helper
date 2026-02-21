-- core/domain/enrichment/internal/enums/moisture.lua
--
-- System-level moisture state model.
-- Canonical 2-letter codes.
-- Used for:
--   • board classification
--   • shrinkage logic selection
--   • validation
--   • reporting
--
-- Structure mirrors grade enum discipline.

local Moisture = {}

----------------------------------------------------------------
-- Moisture States
----------------------------------------------------------------

Moisture.STATE = {

    GR = {
        kind = "value",
        domain = "moisture.state",
        key = "green",
        code = "GR",
        rank = 1,
        shrinkage_active = false,
        description = "Green lumber (above fiber saturation ~30% MC).",
    },

    DR = {
        kind = "value",
        domain = "moisture.state",
        key = "dry",
        code = "DR",
        rank = 2,
        shrinkage_active = false,
        description = "Air-dried lumber (~15–20% MC typical).",
    },

    KD = {
        kind = "value",
        domain = "moisture.state",
        key = "kiln_dried",
        code = "KD",
        rank = 3,
        shrinkage_active = false,
        description = "Kiln dried lumber (~10–12% MC).",
    },

    DY = {
        kind = "value",
        domain = "moisture.state",
        key = "drying",
        code = "DY",
        rank = 4,
        shrinkage_active = true,
        description = "Actively drying (below fiber saturation, shrinking).",
    },
}

----------------------------------------------------------------
-- Shrinkage Coefficients (Green → ~12% MC)
----------------------------------------------------------------
-- Species-specific physical shrinkage factors.
-- Used when solving green rough dimensions.

Moisture.SHRINKAGE = {

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

----------------------------------------------------------------
-- Lookup Sets
----------------------------------------------------------------

Moisture.SET = {}
Moisture._index = {}

for _, def in pairs(Moisture.STATE) do
    Moisture.SET[def.code] = true
    Moisture._index[string.lower(def.code)] = def
    Moisture._index[string.lower(def.key)] = def
end

----------------------------------------------------------------
-- Resolver
----------------------------------------------------------------

function Moisture.get(key)
    if not key then return nil end

    if type(key) == "table" then
        return key
    end

    if type(key) == "string" then
        return Moisture._index[string.lower(key)]
    end

    return nil
end

return Moisture
