-- parsers/raw_text/preprocess.lua
--
-- Raw text preprocessor
-- PURPOSE:
--   • Structural extraction only
--   • Head / tail separation
--   • Assignment extraction
--   • NO tokenization
--   • NO board logic

local Preprocess = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_once(s, sep)
    local a, b = s:match("^(.-)" .. sep .. "(.*)$")
    if a then
        return trim(a), trim(b)
    end
    return trim(s), nil
end

local function split_all(s, sep)
    local out = {}
    for part in s:gmatch("[^" .. sep .. "]+") do
        out[#out + 1] = trim(part)
    end
    return out
end

local function parse_assignment(s)
    local k, v = s:match("^(.-)%s*::%s*(.+)$")
    if k then return trim(k), trim(v) end

    k, v = s:match("^(.-)%s*=%s*(.+)$")
    if k then return trim(k), trim(v) end

    k, v = s:match("^(.-)%s*:%s*(.+)$")
    if k then return trim(k), trim(v) end

    return nil, nil
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param lines string[]
---@return table[] preprocessed_records
function Preprocess.run(lines)
    assert(type(lines) == "table", "Preprocess.run(): lines must be table")

    local records = {}

    for i, line in ipairs(lines) do
        local raw = tostring(line)

        local record = {
            __raw     = raw,
            __line_no = i,
        }

        -- --------------------------------------------
        -- Tier 1: head / tail
        -- --------------------------------------------
        local head, tail = split_once(raw, ";")
        record.head = head

        -- --------------------------------------------
        -- Tier 2: tail assignments
        -- --------------------------------------------
        if tail and tail ~= "" then
            local extras = {}

            for _, segment in ipairs(split_all(tail, ",")) do
                local k, v = parse_assignment(segment)
                if k then
                    record[k] = v
                else
                    extras[#extras + 1] = segment
                end
            end

            if #extras > 0 then
                record._tail_extra = extras
            end
        end

        records[#records + 1] = record
    end

    return records
end

return Preprocess
