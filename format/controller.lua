-- format/controller.lua

local Registry = require("format.registry")
local Validate = Registry.validate.input

local Controller = {}

----------------------------------------------------------------
-- Records formatting
----------------------------------------------------------------

---@param source_kind string
---@param data any
---@return table|nil result
---@return string|nil err
function Controller.to_records(source_kind, data)
    local ok, err = Validate.to_records({
        source_kind = source_kind,
        data        = data,
    })
    if not ok then
        return nil, err
    end

    local formatter = Registry.records["from_" .. source_kind]
    if not formatter then
        return nil, "unsupported records formatter: " .. tostring(source_kind)
    end

    local result, ferr = formatter.run(data)
    if not result then
        return nil, ferr
    end

    -- ENVELOPE ENFORCEMENT (old shape)
    if result.kind ~= "records" then
        return nil, "formatter must return kind='records'"
    end

    if type(result.data) ~= "table" then
        return nil, "records formatter must return data=array"
    end

    return result
end

----------------------------------------------------------------
-- STRICT variant
----------------------------------------------------------------

function Controller.to_records_strict(source_kind, data)
    local result, err = Controller.to_records(source_kind, data)
    if not result then
        error(err, 2)
    end
    return result
end

return Controller
