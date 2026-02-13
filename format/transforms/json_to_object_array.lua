-- format/transforms/json_to_object_array.lua


local Shape = require('format.validate.shape')

local M = {}

function M.run(json_data)

    if type(json_data) ~= "table" then
        return nil, "json root must be table"
    end

    if Shape.object_array(json_data) then
        return json_data
    end

    if Shape.object(json_data) then
        return { json_data }
    end

    return nil, "unsupported json structure"
end

return M
