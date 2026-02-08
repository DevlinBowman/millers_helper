-- io/normalize.lua
--
-- Normalization utilities.
-- Converts codec outputs into record-oriented structures.
--
-- This module:
--   • Does NOT validate semantic correctness
--   • Does NOT infer schemas
--   • Does NOT mutate input objects
--
-- It performs *structural projection only*.

local Normalize = {}

----------------------------------------------------------------
-- Type definitions
----------------------------------------------------------------

---@class IOTableResult
---@field kind "table"
---@field data { header: string[], rows: string[][] }
---@field meta table|nil

---@class IOJsonResult
---@field kind "json"
---@field data table
---@field meta table|nil

---@class IOLinesResult
---@field kind "lines"
---@field data string[]
---@field meta table|nil

---@class IORecordsResult
---@field kind "records"
---@field data table[]                 -- array of record tables
---@field meta { input_fields: string[] }

----------------------------------------------------------------
-- Tabular → records
----------------------------------------------------------------

--- Normalize a tabular codec result into records.
--- Each row becomes a table keyed by header names.
---
---@param result IOTableResult
---@return IORecordsResult
function Normalize.table(result)
    local header = result.data.header
    local rows   = result.data.rows

    local records = {}

    for _, row in ipairs(rows) do
        local rec = {}
        for i, key in ipairs(header) do
            rec[key] = row[i]
        end
        records[#records + 1] = rec
    end

    return {
        kind = "records",
        data = records,
        meta = {
            input_fields = header,
        }
    }
end

----------------------------------------------------------------
-- JSON → records
----------------------------------------------------------------

--- Normalize a JSON codec result into records.
--- Supports:
---   • array-of-objects → records
---   • single object    → singleton record array
---
--- All keys across objects are unioned into `input_fields`.
---
---@param result IOJsonResult
---@return IORecordsResult|nil
---@return string|nil err
function Normalize.json(result)
    local v = result.data
    if type(v) ~= "table" then
        return nil, "json root must be object or array"
    end

    local records = {}
    local input_fields = {}

    local function collect_keys(obj)
        for k in pairs(obj) do
            input_fields[k] = true
        end
    end

    -- array-of-objects
    if #v > 0 then
        for _, obj in ipairs(v) do
            collect_keys(obj)
            records[#records + 1] = obj
        end
    else
        -- single object
        collect_keys(v)
        records = { v }
    end

    local keys = {}
    for k in pairs(input_fields) do
        keys[#keys + 1] = k
    end
    table.sort(keys)

    return {
        kind = "records",
        data = records,
        meta = {
            input_fields = keys,
        }
    }
end

----------------------------------------------------------------
-- Raw text → records (intentionally unimplemented)
----------------------------------------------------------------

--- Placeholder for raw-text normalization.
--- Text normalization is owned by parser pipelines, not IO.
---
---@param result IOLinesResult
---@return nil|string
function Normalize.lines(result)
    return "Normalize.lines is not implemented; text normalization is parser-owned"
end

return Normalize
