-- file_handler/writers/delimited.lua
local DelimitedWriter = {}

local function join(fields, sep)
    return table.concat(fields, sep)
end

function DelimitedWriter.write(path, data, sep)
    assert(type(data) == "table", "data required")
    assert(type(data.header) == "table", "missing header")
    assert(type(data.rows) == "table", "missing rows")

    local fh, err = io.open(path, "w")
    if not fh then return nil, err end

    fh:write(join(data.header, sep), "\n")
    for _, row in ipairs(data.rows) do
        fh:write(join(row, sep), "\n")
    end

    fh:close()
    return true
end

return DelimitedWriter
