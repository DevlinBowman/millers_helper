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

--- Schema-aware dimension extraction (no mutation)
local function resolved_dimensions(record)
    return {
        base_h = resolve(record, "base_h"),
        base_w = resolve(record, "base_w"),
        l      = resolve(record, "l"),
    }
end

--- Check numeric sanity WITHOUT coercion
local function invalid_number(v)
    if v == nil then return false end
    local n = tonumber(v)
    return n == nil or n <= 0
end

----------------------------------------------------------------
-- Missing / invalid dimensions (pre-board diagnostics)
----------------------------------------------------------------

---@param record table
---@return string[] missing
function Validator.missing_dimensions(record)
    local dims = resolved_dimensions(record)
    local missing = {}

    if dims.base_h == nil then
        missing[#missing + 1] = "base_h"
    end
    if dims.base_w == nil then
        missing[#missing + 1] = "base_w"
    end
    if dims.l == nil then
        missing[#missing + 1] = "l"
    end

    return missing
end

---@param record table
---@param index number
---@param head string|nil
---@return table[] signals
function Validator.check_missing_dimensions(record, index, head)
    local missing = Validator.missing_dimensions(record)
    if #missing == 0 then
        return {}
    end

    return {
        {
            level   = "error",
            code    = "board.missing_required_dimensions",
            index   = index,
            head    = head,
            missing = missing,
            message = "Missing required board dimensions: " .. table.concat(missing, ", "),
            note    = "Dimensions may exist under aliases. Verify headers or extend schema aliases.",
        }
    }
end

----------------------------------------------------------------
-- Invalid (non-positive / non-numeric) dimensions
----------------------------------------------------------------

---@param record table
---@param index number
---@param head string|nil
---@return table[] signals
function Validator.check_invalid_dimensions(record, index, head)
    local dims = resolved_dimensions(record)
    local bad = {}

    if invalid_number(dims.base_h) then bad[#bad+1] = "base_h" end
    if invalid_number(dims.base_w) then bad[#bad+1] = "base_w" end
    if invalid_number(dims.l)      then bad[#bad+1] = "l" end

    if #bad == 0 then
        return {}
    end

    return {
        {
            level   = "error",
            code    = "board.invalid_dimension_value",
            index   = index,
            head    = head,
            fields  = bad,
            message = "Invalid board dimension values: " .. table.concat(bad, ", "),
            note    = "Dimensions must be numeric and > 0 after alias resolution.",
        }
    }
end

----------------------------------------------------------------
-- Unmapped fields (schema + alias aware)
----------------------------------------------------------------

local function build_allowset(extra_allowed)
    local allow = { head = true }

    if type(extra_allowed) == "table" then
        for _, k in ipairs(extra_allowed) do
            if type(k) == "string" then
                allow[k] = true
            end
        end
    end

    return allow
end

---@param record table
---@param index number
---@param head string|nil
---@param extra_allowed string[]|nil
---@return table[] signals
function Validator.check_unmapped_fields(record, index, head, extra_allowed)
    local warnings = {}
    local allow = build_allowset(extra_allowed)

    for k, v in pairs(record) do
        if type(k) == "string"
            and not allow[k]
            and not Schema.fields[k]
            and not Schema.alias_index[k]
        then
            warnings[#warnings + 1] = {
                level   = "warning",
                code    = "ingest.unmapped_field",
                index   = index,
                head    = head,
                field   = k,
                value   = v,
                message = "Field could not be mapped to board schema",
                note    = "This field was ignored during board construction. If it matters, add an alias or schema field.",
            }
        end
    end

    return warnings
end

return Validator
