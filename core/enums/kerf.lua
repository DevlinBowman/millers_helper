-- core/enums/kerf.lua
--
-- Physical saw kerf standards.
-- Defines blade material removal width in inches.
--
-- Pure physical classification.
-- No pricing logic.

local Kerf = {}

----------------------------------------------------------------
-- Kerf Values (inches)
----------------------------------------------------------------

Kerf.VALUE = {

    BAND_THIN = {
        kind = "value",
        domain = "process.kerf",
        code = "BK",
        width_in = 0.090,
        description = "Thin bandsaw kerf (~0.090 in).",
    },

    CIRCULAR_STANDARD = {
        kind = "value",
        domain = "process.kerf",
        code = "CK",
        width_in = 0.125,
        description = "Standard circular saw kerf (1/8 in).",
    },

    CIRCULAR_WIDE = {
        kind = "value",
        domain = "process.kerf",
        code = "CW",
        width_in = 0.1875,
        description = "Wide circular blade kerf (3/16 in).",
    },
}

----------------------------------------------------------------
-- Lookup Set
----------------------------------------------------------------

Kerf.SET = {}
Kerf._index = {}

for _, def in pairs(Kerf.VALUE) do
    Kerf.SET[def.code] = true
    Kerf._index[string.lower(def.code)] = def
end

----------------------------------------------------------------
-- Resolver
----------------------------------------------------------------

function Kerf.get(code)
    if not code then return nil end

    if type(code) == "table" then
        return code
    end

    return Kerf._index[string.lower(code)]
end

return Kerf
