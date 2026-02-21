-- core/enums/dimension.lua
--
-- System-level dimensional standards.
-- Defines canonical base dimensions for boards.
--
-- Each entry:
--   kind        = "value"
--   domain      = "dimension.<axis>"
--   value       = numeric base dimension
--   description = semantic meaning

local Dimension = {}

----------------------------------------------------------------
-- Height Base (inches)
----------------------------------------------------------------

Dimension.HEIGHT = {

    D1 = { kind = "value", domain = "dimension.height", value = 1, description = "1 inch nominal height." },
    D2 = { kind = "value", domain = "dimension.height", value = 2, description = "2 inch nominal height." },
    D4 = { kind = "value", domain = "dimension.height", value = 4, description = "4 inch nominal height." },
    D6 = { kind = "value", domain = "dimension.height", value = 6, description = "6 inch nominal height." },
    D8 = { kind = "value", domain = "dimension.height", value = 8, description = "8 inch nominal height." },
    D10 = { kind = "value", domain = "dimension.height", value = 10, description = "10 inch nominal height." },
    D12 = { kind = "value", domain = "dimension.height", value = 12, description = "12 inch nominal height." },
}

----------------------------------------------------------------
-- Width Base (inches)
----------------------------------------------------------------

Dimension.WIDTH = {

    D1 = { kind = "value", domain = "dimension.width", value = 1, description = "1 inch nominal width." },
    D2 = { kind = "value", domain = "dimension.width", value = 2, description = "2 inch nominal width." },
    D4 = { kind = "value", domain = "dimension.width", value = 4, description = "4 inch nominal width." },
    D6 = { kind = "value", domain = "dimension.width", value = 6, description = "6 inch nominal width." },
    D8 = { kind = "value", domain = "dimension.width", value = 8, description = "8 inch nominal width." },
    D10 = { kind = "value", domain = "dimension.width", value = 10, description = "10 inch nominal width." },
    D12 = { kind = "value", domain = "dimension.width", value = 12, description = "12 inch nominal width." },
}

----------------------------------------------------------------
-- Length Base (feet)
----------------------------------------------------------------

Dimension.LENGTH = {

    L5  = { kind = "value", domain = "dimension.length", value = 5, description = "5 foot length." },
    L6  = { kind = "value", domain = "dimension.length", value = 6, description = "6 foot length." },
    L7  = { kind = "value", domain = "dimension.length", value = 7, description = "7 foot length." },
    L8  = { kind = "value", domain = "dimension.length", value = 8, description = "8 foot length." },
    L9  = { kind = "value", domain = "dimension.length", value = 9, description = "9 foot length." },
    L10 = { kind = "value", domain = "dimension.length", value = 10, description = "10 foot length." },
    L12 = { kind = "value", domain = "dimension.length", value = 12, description = "12 foot length." },
    L14 = { kind = "value", domain = "dimension.length", value = 14, description = "14 foot length." },
    L16 = { kind = "value", domain = "dimension.length", value = 16, description = "16 foot length." },
    L18 = { kind = "value", domain = "dimension.length", value = 18, description = "18 foot length." },
    L20 = { kind = "value", domain = "dimension.length", value = 20, description = "20 foot length." },
}

----------------------------------------------------------------
-- Derived Lookup Sets
----------------------------------------------------------------

local function build_set(section)
    local set = {}
    for _, def in pairs(section) do
        set[def.value] = true
    end
    return set
end

Dimension.HEIGHT_SET = build_set(Dimension.HEIGHT)
Dimension.WIDTH_SET  = build_set(Dimension.WIDTH)
Dimension.LENGTH_SET = build_set(Dimension.LENGTH)

----------------------------------------------------------------
-- Validation Helpers
----------------------------------------------------------------

function Dimension.is_valid_height(v)
    return Dimension.HEIGHT_SET[tonumber(v)] == true
end

function Dimension.is_valid_width(v)
    return Dimension.WIDTH_SET[tonumber(v)] == true
end

function Dimension.is_valid_length(v)
    return Dimension.LENGTH_SET[tonumber(v)] == true
end

return Dimension
