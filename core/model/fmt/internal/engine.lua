local Engine = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function resolve_field(object, path)
    local value = object
    for segment in string.gmatch(path, "[^%.]+") do
        if type(value) ~= "table" then
            return nil
        end
        value = value[segment]
    end
    return value
end

local function default_stringify(value)
    if value == nil then
        return ""
    end
    return tostring(value)
end

local function apply_format(column, object, opts)
    local value

    if column.compute then
        value = column.compute(object, opts)
    else
        value = resolve_field(object, column.field)
    end

    if column.format then
        return column.format(value, object, opts)
    end

    return default_stringify(value)
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

--- Run formatting preset
--- @param object table
--- @param preset table
--- @param opts table
--- @return string
function Engine.run(object, preset, opts)
    assert(type(object) == "table", "Engine.run(): object required")
    assert(type(preset) == "table", "Engine.run(): preset table required")
    assert(type(preset.columns) == "table", "preset.columns required")

    local parts = {}

    for _, column in ipairs(preset.columns) do
        parts[#parts + 1] = apply_format(column, object, opts)
    end

    local separator = preset.separator or " "
    return table.concat(parts, separator)
end

return Engine
