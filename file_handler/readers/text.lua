-- file_handler/readers/text.lua
local TextReader = {}

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

local function line_iterator(lines)
    local i = 0
    return function()
        i = i + 1
        return lines[i]
    end
end

function TextReader.read(path)
    local fh, err = io.open(path, "r")
    if not fh then return nil, err end

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

return TextReader
