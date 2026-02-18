-- core/model/allocations/internal/schema.lua
--
-- Canonical Allocation Profile Schema.
-- Defines structured production cost components.

local Schema = {}

----------------------------------------------------------------
-- Roles
----------------------------------------------------------------

Schema.ROLES = {
    AUTHORITATIVE = "authoritative",
    DERIVED       = "derived",
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

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

local function coerce_scope(v)
    if v == nil then return "board" end
    local s = tostring(v)
    if s == "board" or s == "order" or s == "profit" then
        return s
    end
    return nil
end

local function coerce_basis(v)
    if v == nil then return nil end
    local s = tostring(v)
    if s == "per_bf" or s == "fixed" or s == "percent" then
        return s
    end
    return nil
end

----------------------------------------------------------------
-- Profile Schema
----------------------------------------------------------------

Schema.fields = {

    profile_id = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_string,
    },

    description = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_string,
    },

    extends = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_string,
    },

    allocations = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_table,
    },
}

----------------------------------------------------------------
-- Allocation Entry Schema
----------------------------------------------------------------

Schema.allocation_entry = {

    scope = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_scope,
    },

    party = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_string,
    },

    category = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_string,
    },

    amount = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_number,
    },

    basis = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_basis,
    },

    priority = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_number,
    },

    source = {
        role   = Schema.ROLES.AUTHORITATIVE,
        coerce = coerce_string,
    },
}

----------------------------------------------------------------
-- Normalization
----------------------------------------------------------------

function Schema.normalize_allocation_entry(entry)
    local normalized = {}

    for field, def in pairs(Schema.allocation_entry) do
        local value = entry[field]
        if value ~= nil then
            normalized[field] = def.coerce(value)
        end
    end

    return normalized
end

function Schema.normalize_profile(profile)
    local normalized = {}

    for field, def in pairs(Schema.fields) do
        local value = profile[field]
        if value ~= nil then
            normalized[field] = def.coerce(value)
        end
    end

    normalized.allocations = {}

    for _, entry in ipairs(profile.allocations or {}) do
        table.insert(
            normalized.allocations,
            Schema.normalize_allocation_entry(entry)
        )
    end

    return normalized
end

return Schema
