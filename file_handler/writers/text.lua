-- file_handler/writers/text.lua
local TextWriter = {}

function TextWriter.write(path, lines)
    assert(type(lines) == "table", "lines must be a table")

    local fh, err = io.open(path, "w")
    if not fh then return nil, err end

    for _, line in ipairs(lines) do
        fh:write(tostring(line), "\n")
    end

    fh:close()
    return true
end

return TextWriter
