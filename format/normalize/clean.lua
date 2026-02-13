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
--   Normalize codec-native data BEFORE decode/encode.

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
-- Table helpers
----------------------------------------------------------------

local function is_array(t)
    if type(t) ~= "table" then return false end
    local max = 0
    for k in pairs(t) do
        if type(k) ~= "number" then return false end
        if k > max then max = k end
    end
    return max == #t
end

local function looks_like_object_array(t)
    if not is_array(t) then return false end
    for i = 1, #t do
        if type(t[i]) ~= "table" then
            return false
        end
    end
    return true
end

----------------------------------------------------------------
-- Object normalization
----------------------------------------------------------------

local function normalize_object(obj)
    local keys = {}
    for k in pairs(obj) do
        keys[#keys + 1] = k
    end

    for _, raw_key in ipairs(keys) do
        local value = obj[raw_key]

        local new_key = raw_key
        if type(raw_key) == "string" then
            new_key = normalize_string(raw_key)
        end

        local new_val = value
        if type(value) == "string" then
            new_val = normalize_string(value)
        end

        if new_key ~= raw_key then
            obj[raw_key] = nil
            -- collision-safe: keep existing if present
            if obj[new_key] == nil then
                obj[new_key] = new_val
            end
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
---@return any data -- same table (mutated in place where applicable)
function Clean.apply(codec, data)
    if type(data) ~= "table" then
        return data
    end

    -- canonical objects
    if codec == "objects" then
        if looks_like_object_array(data) then
            for i = 1, #data do
                normalize_object(data[i])
            end
        else
            -- if someone passes a single object table by mistake,
            -- still normalize it (harmless, and fixes junk keys/values)
            normalize_object(data)
        end
        return data
    end

    -- json is decoded to Lua tables by IO; normalize as object(s)
    if codec == "json" then
        if looks_like_object_array(data) then
            for i = 1, #data do
                normalize_object(data[i])
            end
        else
            normalize_object(data)
        end
        return data
    end

    -- delimited logical table
    if codec == "delimited" then
        if type(data.header) == "table" then
            for i = 1, #data.header do
                if type(data.header[i]) == "string" then
                    data.header[i] = normalize_string(data.header[i])
                end
            end
        end

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

        return data
    end

    -- lines
    if codec == "lines" then
        for i = 1, #data do
            if type(data[i]) == "string" then
                data[i] = normalize_string(data[i])
            end
        end
        return data
    end

    -- unknown codec: do nothing
    return data
end

return Clean
