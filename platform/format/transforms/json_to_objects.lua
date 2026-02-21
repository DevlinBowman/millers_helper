-- format/transforms/json_to_objects.lua

local Shape = require("platform.format.validate.shape")

local M = {}

function M.run(json_data)

    if type(json_data) ~= "table" then
        return nil, "json root must be table"
    end

    if Shape.objects(json_data) then
        return json_data
    end

    if type(json_data) == "table" then
        return { json_data }
    end

    return nil, "unsupported json structure"
end

return M
