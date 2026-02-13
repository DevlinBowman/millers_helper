-- format/transforms/object_array_to_lines.lua

local Shape = require('format.validate.shape')

local M = {}

local function stringify_object(obj)
    local keys = {}
    for k in pairs(obj) do
        keys[#keys + 1] = k
    end
    table.sort(keys)

    local parts = {}
    for _, k in ipairs(keys) do
        parts[#parts + 1] = k .. "=" .. tostring(obj[k])
    end

    return table.concat(parts, " ")
end

function M.run(object_array)

    if not Shape.object_array(object_array) then
        return nil, "invalid object_array shape"
    end

    local lines = {}

    for _, obj in ipairs(object_array) do
        lines[#lines + 1] = stringify_object(obj)
    end

    return lines
end

return M
