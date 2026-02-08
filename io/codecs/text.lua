-- io/codecs/text.lua
--
-- Plain text codec.

---@class TextReadResult
---@field kind "lines"
---@field data string[]
---@field iter fun(): (fun(): string|nil)

---@class TextCodec
---@field read fun(path:string): TextReadResult
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

---@param lines string[]
---@return fun(): string|nil
local function line_iterator(lines)
    local i = 0
    return function()
        i = i + 1
        return lines[i]
    end
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
        kind = "lines",
        data = lines,
        iter = function()
            return line_iterator(lines)
        end,
    }
end


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
