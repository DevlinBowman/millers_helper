-- io/codecs/json.lua
--
-- JSON codec: read + write
--
-- Contract:
--   • read(path)  -> { kind = "json", data = any } | throws
--   • write(path, value) -> true | throws
--
-- Notes:
--   • Strict JSON (no Lua literals)
--   • No schema inference
--   • No pretty-printing
--   • Deterministic, lossless for JSON-safe Lua values

---@class JsonReadResult
---@field kind "json"
---@field data any

local Json = {}

----------------------------------------------------------------
-- Reader internals
----------------------------------------------------------------

---@param pos integer
---@param msg string
local function error_at(pos, msg)
    error(string.format("JSON error at %d: %s", pos, msg), 2)
end

---@param src string
---@return any
local function parse(src)
    local pos = 1
    local len = #src

    local function peek()
        return src:sub(pos, pos)
    end

    local function next_char()
        pos = pos + 1
    end

    local function skip_ws()
        while pos <= len and peek():match("%s") do
            pos = pos + 1
        end
    end

    ----------------------------------------------------------------
    -- String
    ----------------------------------------------------------------

    local function parse_string()
        -- opening quote already consumed
        local out = {}

        while true do
            local c = peek()
            if c == "" then
                error_at(pos, "unterminated string")
            end

            if c == '"' then
                next_char()
                return table.concat(out)
            end

            if c == "\\" then
                local esc = src:sub(pos + 1, pos + 1)
                local map = {
                    ['"']  = '"',
                    ['\\'] = '\\',
                    ['/']  = '/',
                    ['b']  = '\b',
                    ['f']  = '\f',
                    ['n']  = '\n',
                    ['r']  = '\r',
                    ['t']  = '\t',
                }
                local v = map[esc]
                if not v then
                    error_at(pos, "invalid escape")
                end
                out[#out + 1] = v
                pos = pos + 2
            else
                out[#out + 1] = c
                next_char()
            end
        end
    end

    ----------------------------------------------------------------
    -- Number
    ----------------------------------------------------------------

    local function parse_number()
        local start = pos
        while pos <= len and src:sub(pos, pos):match("[%d%+%-%eE%.]") do
            pos = pos + 1
        end

        local n = tonumber(src:sub(start, pos - 1))
        if not n then
            error_at(start, "invalid number")
        end
        return n
    end

    ----------------------------------------------------------------
    -- Forward decl
    ----------------------------------------------------------------

    local parse_value

    ----------------------------------------------------------------
    -- Array
    ----------------------------------------------------------------

    local function parse_array()
        next_char() -- '['
        skip_ws()

        local out = {}
        if peek() == "]" then
            next_char()
            return out
        end

        while true do
            out[#out + 1] = parse_value()
            skip_ws()

            local c = peek()
            if c == "]" then
                next_char()
                return out
            end
            if c ~= "," then
                error_at(pos, "expected ','")
            end
            next_char()
            skip_ws()
        end
    end

    ----------------------------------------------------------------
    -- Object
    ----------------------------------------------------------------

    local function parse_object()
        next_char() -- '{'
        skip_ws()

        local out = {}
        if peek() == "}" then
            next_char()
            return out
        end

        while true do
            if peek() ~= '"' then
                error_at(pos, "object keys must be strings")
            end
            next_char()
            local key = parse_string()
            skip_ws()

            if peek() ~= ":" then
                error_at(pos, "expected ':'")
            end
            next_char()
            skip_ws()

            out[key] = parse_value()
            skip_ws()

            local c = peek()
            if c == "}" then
                next_char()
                return out
            end
            if c ~= "," then
                error_at(pos, "expected ','")
            end
            next_char()
            skip_ws()
        end
    end

    ----------------------------------------------------------------
    -- Value
    ----------------------------------------------------------------

    function parse_value()
        skip_ws()
        local c = peek()

        if c == '"' then
            next_char()
            return parse_string()
        elseif c == "{" then
            return parse_object()
        elseif c == "[" then
            return parse_array()
        elseif c:match("[%d%-]") then
            return parse_number()
        elseif src:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif src:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif src:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            error_at(pos, "unexpected token")
        end
    end

    ----------------------------------------------------------------
    -- Entry
    ----------------------------------------------------------------

    local value = parse_value()
    skip_ws()
    if pos <= len then
        error_at(pos, "trailing data")
    end
    return value
end

----------------------------------------------------------------
-- Public reader
----------------------------------------------------------------

---@param path string
---@return JsonReadResult
function Json.read(path)
    local fh, err = io.open(path, "r")
    if not fh then
        error(err)
    end

    local src = fh:read("*a")
    fh:close()

    local ok, value = pcall(parse, src)
    if not ok then
        error(value)
    end

    return {
        kind = "json",
        data = value,
    }
end

----------------------------------------------------------------
-- Writer internals
----------------------------------------------------------------

---@param s string
---@return string
local function escape_string(s)
    s = s
        :gsub('\\', '\\\\')
        :gsub('"', '\\"')
        :gsub('\b', '\\b')
        :gsub('\f', '\\f')
        :gsub('\n', '\\n')
        :gsub('\r', '\\r')
        :gsub('\t', '\\t')

    return s
end

---@param t table
---@return boolean
local function is_array_table(t)
    local max = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k <= 0 or k % 1 ~= 0 then
            return false
        end
        if k > max then
            max = k
        end
    end
    return max == #t
end

---@param v any
---@return string
local function encode(v)
    local t = type(v)

    if t == "nil" then
        return "null"
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then
            error("invalid JSON number")
        end
        return tostring(v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return '"' .. escape_string(v) .. '"'
    elseif t == "table" then
        local out = {}

        if is_array_table(v) then
            for i = 1, #v do
                out[#out + 1] = encode(v[i])
            end
            return "[" .. table.concat(out, ",") .. "]"
        else
            for k, val in pairs(v) do
                if type(k) ~= "string" then
                    error("JSON object keys must be strings")
                end
                out[#out + 1] =
                    encode(k) .. ":" .. encode(val)
            end
            return "{" .. table.concat(out, ",") .. "}"
        end
    else
        error("unsupported JSON type: " .. t)
    end
end

----------------------------------------------------------------
-- Public writer
----------------------------------------------------------------

---@param path string
---@param value any
---@return true
function Json.write(path, value)
    local fh, err = io.open(path, "w")
    if not fh then
        error(err)
    end

    fh:write(encode(value))
    fh:close()
    return true
end

return Json
