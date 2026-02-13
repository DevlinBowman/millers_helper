-- format/transforms/table_to_object_array.lua

local Shape = require('format.validate.shape')

local M = {}

function M.run(table_data)

    if not Shape.table(table_data) then
        return nil, "invalid table shape"
    end

    local header = table_data.header
    local rows   = table_data.rows

    local out = {}

    for _, row in ipairs(rows) do
        local obj = {}
        for i, key in ipairs(header) do
            obj[key] = row[i]
        end
        out[#out + 1] = obj
    end

    return out
end

return M
