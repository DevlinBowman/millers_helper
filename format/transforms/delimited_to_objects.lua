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

        -- Defensive header-leak guard:
        -- If the row exactly matches header, skip it.
        local is_header_row = true

        for i, key in ipairs(header) do
            if tostring(row[i]) ~= tostring(key) then
                is_header_row = false
                break
            end
        end

        if not is_header_row then
            local obj = {}
            local empty = true

            for i, key in ipairs(header) do
                local value = row[i]

                if value ~= nil and tostring(value) ~= "" then
                    obj[key] = value
                    empty = false
                end
            end

            -- Skip fully empty rows
            if not empty then
                objects[#objects + 1] = obj
            end
        end
    end

    return objects
end

return M

