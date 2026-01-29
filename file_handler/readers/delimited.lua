-- file_handler/readers/delimited.lua
local Delimited = {}

local function split(line, sep)
    local out = {}
    local pattern = string.format("([^%s]+)", sep)
    for field in line:gmatch(pattern) do
        out[#out + 1] = field
    end
    return out
end

local function row_iterator(rows)
    local i = 0
    return function()
        i = i + 1
        return rows[i]
    end
end

function Delimited.read(path, sep)
    local fh, err = io.open(path, "r")
    if not fh then return nil, err end

    local header
    local rows = {}

    for line in fh:lines() do
        if not header then
            header = split(line, sep)
        else
            rows[#rows + 1] = split(line, sep)
        end
    end
    fh:close()

    if not header then
        return nil, "missing header row"
    end

    for i, row in ipairs(rows) do
        if #row ~= #header then
            return nil, string.format(
                "row %d has %d fields (expected %d)",
                i, #row, #header
            )
        end
    end

    return {
        kind = "table",
        data = {
            header = header,
            rows   = rows,
        },
        iter = function()
            return row_iterator(rows)
        end,
    }
end

return Delimited
