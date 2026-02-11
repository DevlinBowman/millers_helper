-- format/validate/input.lua
--
-- Admission validation for formatting.

local Validate = {}

function Validate.to_records(input)
    if type(input) ~= "table" then
        return nil, "format input must be table"
    end

    if type(input.source_kind) ~= "string" then
        return nil, "source_kind required"
    end

    if input.data == nil then
        return nil, "format requires data"
    end

    return true
end

return Validate
