-- io/codecs/text.lua
--
-- Plain text codec.
--
-- Contract:
--   • read(path)  -> { codec = "lines", data = string[] } | throws
--   • write(path, lines) -> true | throws

---@class TextReadResult
---@field codec "lines"
---@field data  string[]

---@class TextCodec
---@field read  fun(path:string): TextReadResult
---@field write fun(path:string, lines:string[]): true

local TextReader = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

---@param lines string[]
---@return string[]
local function strip_empty(lines)
    local out = {}

    for _, line in ipairs(lines) do
        local s = line:match("^%s*(.-)%s*$")
        if s ~= "" then
            out[#out + 1] = s
        end
    end

    return out
end

----------------------------------------------------------------
-- Read
----------------------------------------------------------------

---@param path string
---@return TextReadResult
function TextReader.read(path)
    local fh, err = io.open(path, "r")
    if not fh then
        error(err)
    end

    local lines = {}

    for line in fh:lines() do
        lines[#lines + 1] = line
    end

    fh:close()

    lines = strip_empty(lines)

    return {
        codec = "lines",
        data  = lines,
    }
end

----------------------------------------------------------------
-- Write
----------------------------------------------------------------

---@param path string
---@param lines string[]
---@return true
function TextReader.write(path, lines)
    assert(type(lines) == "table", "lines must be table")

    local fh, err = io.open(path, "w")
    if not fh then
        error(err)
    end

    for _, line in ipairs(lines) do
        fh:write(tostring(line), "\n")
    end

    fh:close()

    return true
end

return TextReader
