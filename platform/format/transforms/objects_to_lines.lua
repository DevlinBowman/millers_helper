-- format/transforms/objects_to_lines.lua

local Shape = require("platform.format.validate.shape")

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

function M.run(objects)

    if not Shape.objects(objects) then
        return nil, "invalid objects shape"
    end

    local lines = {}

    for _, obj in ipairs(objects) do
        lines[#lines + 1] = stringify_object(obj)
    end

    return lines
end

return M
