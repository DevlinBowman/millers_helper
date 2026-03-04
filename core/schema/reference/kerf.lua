-- core/schema/reference/kerf.lua
--
-- Physical saw kerf reference data.
-- Engineering dataset only.
-- Not part of semantic validation system.

local Kerf = {}

----------------------------------------------------------------
-- Standard Kerf Profiles
----------------------------------------------------------------

Kerf.profiles = {

    BAND_THIN = {
        code        = "BK",
        width_in    = 0.0625,
        description = "Thin bandsaw kerf (1/16 in).",
    },

    CIRCULAR_1 = {
        code        = "CK",
        width_in    = 0.125,
        description = "Standard circular saw kerf (1/8 in).",
    },

    CIRCULAR_2 = {
        code        = "CW",
        width_in    = 0.1875,
        description = "Wide circular blade kerf (3/16 in).",
    },

    CIRCULAR_3 = {
        code        = "CW",
        width_in    = 0.3125,
        description = "Wide circular blade kerf (5/16 in).",
    },
}

----------------------------------------------------------------
-- Index
----------------------------------------------------------------

local index = {}

for _, def in pairs(Kerf.profiles) do
    index[string.lower(def.code)] = def
end

----------------------------------------------------------------
-- Resolver
----------------------------------------------------------------

function Kerf.get(code)
    if not code then return nil end
    if type(code) == "table" then return code end
    return index[string.lower(code)]
end

return Kerf
