-- core/domain/enrichment/internal/enums/surface.lua
--
-- System-level surface standards.
-- Canonical 2-letter codes used across:
--   • board normalization
--   • validation
--   • reporting
--   • enrichment expansion
--
-- Each entry:
--   kind        = "value"
--   domain      = "surface.standard"
--   value       = canonical system code
--   description = meaning
--   aliases     = accepted input variants

local SurfaceEnums = {}

----------------------------------------------------------------
-- Surface Standards
----------------------------------------------------------------

SurfaceEnums.SURFACE = {

    RO = {
        kind = "value",
        domain = "surface.standard",
        value = "RO",
        description = "Rough sawn. No surfacing applied.",
        aliases = { "rough", "r", "raw" },
    },

    S1 = {
        kind = "value",
        domain = "surface.standard",
        value = "S1",
        description = "Surfaced on one side.",
        aliases = { "s1s", "1s" },
    },

    S2 = {
        kind = "value",
        domain = "surface.standard",
        value = "S2",
        description = "Surfaced on two sides.",
        aliases = { "s2s", "2s" },
    },

    S3 = {
        kind = "value",
        domain = "surface.standard",
        value = "S3",
        description = "Surfaced on three sides.",
        aliases = { "s3s", "3s" },
    },

    S4 = {
        kind = "value",
        domain = "surface.standard",
        value = "S4",
        description = "Surfaced on four sides.",
        aliases = { "s4s", "4s" },
    },
}

----------------------------------------------------------------
-- Derived Lookup Tables
----------------------------------------------------------------

SurfaceEnums.SET = {}
SurfaceEnums.ALIAS_MAP = {}

for _, def in pairs(SurfaceEnums.SURFACE) do
    SurfaceEnums.SET[def.value] = true

    -- canonical value also resolves to itself
    SurfaceEnums.ALIAS_MAP[string.lower(def.value)] = def.value

    if type(def.aliases) == "table" then
        for _, alias in ipairs(def.aliases) do
            SurfaceEnums.ALIAS_MAP[string.lower(alias)] = def.value
        end
    end
end

----------------------------------------------------------------
-- Normalization Helper
----------------------------------------------------------------

function SurfaceEnums.normalize(input)
    if not input then
        return nil
    end

    local key = string.lower(tostring(input))
    return SurfaceEnums.ALIAS_MAP[key]
end

return SurfaceEnums
