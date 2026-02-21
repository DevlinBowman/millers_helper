-- parsers/pipelines/text_engine/internal/preprocess.lua
--
-- Structural preprocess adapter for text_engine
-- PURPOSE:
--   • Accept string | string[] | record[]
--   • Emit record[] with { index, head, raw }
--   • NO parsing, NO token logic

local Preprocess = {}

local function split_lines(raw)
    local out = {}
    raw = raw:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in raw:gmatch("([^\n]*)\n?") do
        if line == "" and #out > 0 then
            -- gmatch trailing behavior; stop once we’ve consumed final empty
            break
        end
        out[#out + 1] = line
    end
    return out
end

local function is_record(v)
    return type(v) == "table" and (v.head ~= nil or v.raw ~= nil)
end

---@param lines string|table
---@return table[] records
function Preprocess.run(lines)
    if type(lines) == "string" then
        local list = split_lines(lines)
        local records = {}
        for i, s in ipairs(list) do
            records[#records + 1] = { index = i, head = s, raw = s }
        end
        return records
    end

    if type(lines) == "table" then
        if is_record(lines[1]) then
            -- normalize index if missing
            for i, r in ipairs(lines) do
                r.index = r.index or i
                r.head  = r.head or r.raw or ""
                r.raw   = r.raw or r.head
            end
            return lines
        end

        -- assume string[]
        local records = {}
        for i, s in ipairs(lines) do
            records[#records + 1] = { index = i, head = tostring(s), raw = tostring(s) }
        end
        return records
    end

    error("text_engine.preprocess.run(): lines must be string or table")
end

return Preprocess
