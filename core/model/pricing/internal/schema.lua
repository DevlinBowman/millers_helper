-- core/model/pricing/internal/schema.lua
--
-- Canonical Pricing Profile Schema.
-- Defines nonlinear multipliers + markup rules + discount ladders.

local Schema = {}

Schema.ROLES = {
    AUTHORITATIVE = "authoritative",
    DERIVED       = "derived",
}

local function coerce_string(v)
    if v == nil then return nil end
    return tostring(v)
end

local function coerce_number(v)
    if v == nil then return nil end
    return tonumber(v)
end

local function coerce_table(v)
    if type(v) == "table" then return v end
    return nil
end

local function coerce_bool(v)
    if v == nil then return nil end
    if type(v) == "boolean" then return v end
    local s = tostring(v):lower()
    if s == "true" then return true end
    if s == "false" then return false end
    return nil
end

----------------------------------------------------------------
-- Profile schema
----------------------------------------------------------------

Schema.fields = {
    profile_id = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_string },
    description = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_string },
    extends = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_string },

    -- Core knobs
    overhead_per_bf = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_number },   -- company overhead floor
    base_markup_pct = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_number },   -- default markup on cost floor
    min_margin_per_bf = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_number }, -- absolute min margin $/bf

    -- Nonlinear factors
    grade_curve = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_table },        -- map grade -> factor
    size_curve  = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_table },        -- piecewise
    length_curve = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_table },       -- piecewise

    -- Waste / kerf / custom work
    custom_order = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_table },       -- { enabled, waste_curve, rush_curve, small_piece_curve }
    retail_discount_points = { role = Schema.ROLES.AUTHORITATIVE, coerce = coerce_table }, -- { 0, 5, 10, ... } percent
}

----------------------------------------------------------------
-- Normalization
----------------------------------------------------------------

function Schema.normalize_profile(profile)
    local normalized = {}
    for field, def in pairs(Schema.fields) do
        local v = profile[field]
        if v ~= nil then normalized[field] = def.coerce(v) end
    end
    return normalized
end

return Schema
