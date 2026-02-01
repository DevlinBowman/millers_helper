-- ingestion_v2/record_validator.lua
--
-- Responsibility:
--   Emit diagnostic signals ONLY.
--   Alias-aware, schema-driven.
--   Never mutates records.
--   Never throws.
--   Never blocks Board.new().
--
-- Contract:
--   Validator interprets records exactly the way Board.new() will,
--   but does NOT enforce or coerce.

local Schema = require("core.board.schema")

local Validator = {}

----------------------------------------------------------------
-- Internal helpers (schema-aware, non-mutating)
----------------------------------------------------------------

--- Resolve canonical value for a field using schema aliases
--- First-hit wins, no coercion
local function resolve(record, canonical)
    if record[canonical] ~= nil then
        return record[canonical]
    end

    local def = Schema.fields[canonical]
    if not def or not def.aliases then
        return nil
    end

    for _, alias in ipairs(def.aliases) do
        if record[alias] ~= nil then
            return record[alias]
        end
    end

    return nil
end

local function resolved_dimensions(record)
    return {
        base_h = resolve(record, "base_h"),
        base_w = resolve(record, "base_w"),
        l      = resolve(record, "l"),
    }
end

local function invalid_number(v)
    if v == nil then return false end
    local n = tonumber(v)
    return n == nil or n <= 0
end

----------------------------------------------------------------
-- Missing dimensions
----------------------------------------------------------------

function Validator.missing_dimensions(record)
    local dims = resolved_dimensions(record)
    local missing = {}

    if dims.base_h == nil then missing[#missing+1] = "base_h" end
    if dims.base_w == nil then missing[#missing+1] = "base_w" end
    if dims.l == nil then missing[#missing+1] = "l" end

    return missing
end

function Validator.check_missing_dimensions(record, index, head)
    local missing = Validator.missing_dimensions(record)
    if #missing == 0 then return {} end

    return {
        {
            level   = "error",
            code    = "board.missing_required_dimensions",
            index   = index,
            head    = head,

            role    = "authoritative",
            action  = "missing",
            key     = table.concat(missing, ", "),

            message = "Missing required board dimensions",
            note    = "Dimensions may exist under aliases. Verify headers or extend schema aliases.",
        }
    }
end

----------------------------------------------------------------
-- Invalid dimensions
----------------------------------------------------------------

function Validator.check_invalid_dimensions(record, index, head)
    local dims = resolved_dimensions(record)
    local bad = {}

    if invalid_number(dims.base_h) then bad[#bad+1] = "base_h" end
    if invalid_number(dims.base_w) then bad[#bad+1] = "base_w" end
    if invalid_number(dims.l)      then bad[#bad+1] = "l" end

    if #bad == 0 then return {} end

    return {
        {
            level   = "error",
            code    = "board.invalid_dimension_value",
            index   = index,
            head    = head,

            role    = "authoritative",
            action  = "invalid",
            key     = table.concat(bad, ", "),

            message = "Invalid board dimension values",
            note    = "Dimensions must be numeric and > 0 after alias resolution.",
        }
    }
end

----------------------------------------------------------------
-- Derived-field overrides
----------------------------------------------------------------

function Validator.check_derived_field_overrides(record, index, head)
    local infos = {}

    for k, v in pairs(record) do
        if type(k) == "string" then
            local canonical = Schema.alias_index[k] or k
            local def = Schema.fields[canonical]

            if def and def.role == Schema.ROLES.DERIVED and v ~= nil then
                infos[#infos + 1] = {
                    level   = "info",
                    code    = "ingest.derived_field_overridden",
                    index   = index,
                    head    = head,

                    role          = "derived",

                    key           = canonical,
                    input_key     = k,
                    input_value   = v,

                    action        = "recomputed",

                    outcome_key   = canonical,
                    outcome_value = nil, -- patched later

                    message = "Derived field overridden",
                    note    = "This field is calculated internally by the board system. Input value was ignored.",
                }
            end
        end
    end

    return infos
end

----------------------------------------------------------------
-- Unmapped fields
----------------------------------------------------------------

local function build_allowset(extra_allowed)
    local allow = { head = true }
    if type(extra_allowed) == "table" then
        for _, k in ipairs(extra_allowed) do
            allow[k] = true
        end
    end
    return allow
end

function Validator.check_unmapped_fields(record, index, head, extra_allowed)
    local warnings = {}
    local allow = build_allowset(extra_allowed)

    for k, v in pairs(record) do
        if type(k) == "string" and not allow[k] then
            local canonical = Schema.alias_index[k]
            if not canonical and not Schema.fields[k] then
                warnings[#warnings + 1] = {
                    level   = "warning",
                    code    = "ingest.unmapped_field",
                    index   = index,
                    head    = head,

                    role          = "unknown",

                    key           = k,
                    input_key     = k,
                    input_value   = v,

                    action        = "ignored",

                    outcome_key   = k,
                    outcome_value = nil,

                    message = "Field could not be mapped to board schema",
                    note    = "This field was ignored during board construction.",
                }
            end
        end
    end

    return warnings
end

return Validator
