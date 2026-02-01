-- ingestion_v2/record_hygiene.lua
--
-- Responsibility:
--   Mechanical input hygiene for records.
--
-- Performs:
--   • Strip ASCII control characters from keys and string values
--   • Trim leading/trailing whitespace
--
-- Does NOT:
--   • Validate
--   • Coerce
--   • Infer
--   • Know about schema
--   • Emit warnings
--
-- This MUST run:
--   AFTER reader
--   BEFORE record_builder / validator / Board.new

local Hygiene = {}

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

-- ASCII control chars: 0–31 and 127
local function strip_control_chars(s)
    return s:gsub("[%c\127]", "")
end

local function normalize_string(s)
    -- order matters: strip controls, then trim
    s = strip_control_chars(s)
    s = s:match("^%s*(.-)%s*$")
    return s
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param record table
---@return table record -- same table, mutated in-place
function Hygiene.apply(record)
    assert(type(record) == "table", "record_hygiene.apply(): record must be table")

    -- snapshot keys to avoid mutation hazards
    local keys = {}
    for k in pairs(record) do
        keys[#keys + 1] = k
    end

    for _, raw_key in ipairs(keys) do
        local value = record[raw_key]

        -- normalize key if string (strip, trim, lowercase)
        if type(raw_key) == "string" then
            local clean_key = normalize_string(raw_key):lower()

            if clean_key ~= raw_key then
                -- collision-safe
                if record[clean_key] == nil then
                    record[clean_key] = value
                end
                record[raw_key] = nil
                raw_key = clean_key
                value = record[raw_key]
            end
        end

        -- normalize string values
        if type(value) == "string" then
            record[raw_key] = normalize_string(value)
        end
    end

    return record
end

return Hygiene
