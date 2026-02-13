-- format/transforms/delimited_to_table.lua

local Shape = require("format.validate.shape")

local M = {}

function M.run(objects)

    if not Shape.objects(objects) then
        return nil, "invalid objects shape"
    end

    local header_map = {}

    for _, obj in ipairs(objects) do
        for k in pairs(obj) do
            header_map[k] = true
        end
    end

    local header = {}
    for k in pairs(header_map) do
        header[#header + 1] = k
    end
    table.sort(header)

    local rows = {}

    for _, obj in ipairs(objects) do
        local row = {}
        for i, key in ipairs(header) do
            row[i] = tostring(obj[key] or "")
        end
        rows[#rows + 1] = row
    end

    return {
        header = header,
        rows   = rows,
    }
end

return M
