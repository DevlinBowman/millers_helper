-- format/transforms/delimited_to_objects.lua

local Shape = require("format.validate.shape")

local M = {}

function M.run(table_data)

    if not Shape.delimited(table_data) then
        return nil, "invalid delimited shape"
    end

    local header = table_data.header
    local rows   = table_data.rows

    local objects = {}

    for _, row in ipairs(rows) do
        local obj = {}
        for i, key in ipairs(header) do
            obj[key] = row[i]
        end
        objects[#objects + 1] = obj
    end

    return objects
end

return M

