-- tools/struct/init.lua

local StructTool = {}

----------------------------------------------------------------
-- Sections
----------------------------------------------------------------

StructTool.schema    = require("tools.struct.schema")
StructTool.contract  = require("tools.struct.contract")
StructTool.spec      = require("tools.struct.spec")
StructTool.parser    = require("tools.struct.parser")
StructTool.enum      = require("tools.struct.enum")
StructTool.normalize = require("tools.struct.normalize")
StructTool.alias     = require("tools.struct.alias")

----------------------------------------------------------------
-- Section Registry
----------------------------------------------------------------

local SECTIONS = {
    schema    = StructTool.schema,
    contract  = StructTool.contract,
    spec      = StructTool.spec,
    parser    = StructTool.parser,
    enum      = StructTool.enum,
    normalize = StructTool.normalize,
    alias     = StructTool.alias,
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function validate_section(name)
    local section = SECTIONS[name]
    assert(section, "unknown struct category: " .. tostring(name))
    assert(type(section.list) == "function", "section missing list(): " .. name)
    assert(type(section.print) == "function", "section missing print(): " .. name)
    return section
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Print everything in every category.
function StructTool.print_all()
    for _, name in ipairs(StructTool.categories()) do
        StructTool.print_category(name)
    end
end

--- Print all entries within a single category.
--- @param name string
function StructTool.print_category(name)
    local section = validate_section(name)

    for _, key in ipairs(section.list()) do
        section.print(key)
    end
end

--- Return sorted list of available categories.
--- @return string[]
function StructTool.categories()
    local out = {}
    for name in pairs(SECTIONS) do
        out[#out + 1] = name
    end
    table.sort(out)
    return out
end

return StructTool
