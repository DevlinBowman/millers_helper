-- ingestion_v2/record_validator.lua
--
-- Responsibility:
--   Emit diagnostic signals ONLY.
--   Never throws.
--   Never blocks Board.new().
--   Never duplicates Board errors.
--
-- Notes:
--   • Missing-dimension checks are *pre-board signals* so clients can see
--     what's wrong even if Board.new() later throws.
--   • Unmapped-field warnings are schema-based diagnostics, not enforcement.

local Schema = require("core.board.schema")

local Validator = {}

----------------------------------------------------------------
-- Missing required dimensions (pre-board)
----------------------------------------------------------------

---@param record table
---@return string[] missing
function Validator.missing_dimensions(record)
    local missing = {}

    if not (record.base_h or record.h) then
        missing[#missing + 1] = "base_h"
    end
    if not (record.base_w or record.w) then
        missing[#missing + 1] = "base_w"
    end
    if record.l == nil then
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
            note    = "Please update this line or extend parser rules to handle this case.",
        }
    }
end

----------------------------------------------------------------
-- Unmapped (non-schema) fields
----------------------------------------------------------------

local function build_allowset(extra_allowed)
    local allow = {
        head = true, -- always allowed (human line)
    }

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
            and not Schema.fields[k]          -- canonical
            and not Schema.alias_index[k]     -- alias (THIS WAS MISSING)
        then
            warnings[#warnings + 1] = {
                level   = "warning",
                code    = "ingest.unmapped_field",
                index   = index,
                head    = head,
                field   = k,
                value   = v,
                message = "Field could not be mapped to board schema",
                note    = "This field was ignored during board construction. If it matters, add it to schema or allowlist it.",
            }
        end
    end

    return warnings
end

return Validator
