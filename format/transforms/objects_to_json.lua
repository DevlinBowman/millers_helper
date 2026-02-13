-- format/transforms/objects_to_json.lua
--
-- Structural projection: objects -> json-compatible Lua table
-- (IO json codec is responsible for encoding to string.)

local Shape = require("format.validate.shape")

local M = {}

function M.run(objects)
    if not Shape.objects(objects) then
        return nil, "invalid objects shape"
    end

    -- JSON encoder expects array-of-objects (Lua table)
    return objects
end

return M
