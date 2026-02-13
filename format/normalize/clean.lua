-- format/normalize/clean.lua
--
-- Structural mechanical normalization.
--
-- Responsibility:
--   • Remove ASCII control characters from string keys/values
--   • Trim leading/trailing whitespace
--
-- Does NOT:
--   • Validate
--   • Coerce types
--   • Infer schema
--   • Lowercase keys
--   • Touch meta
--
-- Intended use:
--   Normalize payload.data before conversion.

local Clean = {}

----------------------------------------------------------------
-- String helpers
----------------------------------------------------------------

-- ASCII control chars: 0–31 and 127
local function strip_control(s)
    return s:gsub("[%c\127]", "")
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function normalize_string(s)
    s = strip_control(s)
    s = trim(s)
    return s
end

----------------------------------------------------------------
-- Object normalization
----------------------------------------------------------------

local function normalize_object(obj)
    local keys = {}

    -- snapshot keys to avoid mutation hazards
    for k in pairs(obj) do
        keys[#keys + 1] = k
    end

    for _, raw_key in ipairs(keys) do
        local value = obj[raw_key]
        local new_key = raw_key
        local new_val = value

        if type(raw_key) == "string" then
            new_key = normalize_string(raw_key)
        end

        if type(value) == "string" then
            new_val = normalize_string(value)
        end

        if new_key ~= raw_key then
            obj[raw_key] = nil
            obj[new_key] = new_val
        else
            obj[raw_key] = new_val
        end
    end
end

----------------------------------------------------------------
-- Shape dispatch
----------------------------------------------------------------

---@param codec string
---@param data any
---@return any data -- same table (mutated in place)
function Clean.apply(codec, data)

    if type(data) ~= "table" then
        return data
    end

    if codec == "object_array" then
        for i = 1, #data do
            if type(data[i]) == "table" then
                normalize_object(data[i])
            end
        end

    elseif codec == "table" then
        -- normalize header
        if type(data.header) == "table" then
            for i = 1, #data.header do
                if type(data.header[i]) == "string" then
                    data.header[i] = normalize_string(data.header[i])
                end
            end
        end

        -- normalize rows
        if type(data.rows) == "table" then
            for _, row in ipairs(data.rows) do
                if type(row) == "table" then
                    for i = 1, #row do
                        if type(row[i]) == "string" then
                            row[i] = normalize_string(row[i])
                        end
                    end
                end
            end
        end

    elseif codec == "lines" then
        for i = 1, #data do
            if type(data[i]) == "string" then
                data[i] = normalize_string(data[i])
            end
        end

    elseif codec == "object" then
        normalize_object(data)
    end

    return data
end

return Clean
