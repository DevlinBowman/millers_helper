-- tools/struct/alias.lua

local Printer = require("tools.struct._printer")

---@alias AliasKey
---| "classify.alias"
---| "classify.normalize"
---| "parser.token_mappings"

local M = {}

local MAP = {
    ["classify.alias"] =
        "classify.internal.alias",

    ["classify.normalize"] =
        "classify.internal.normalize",

    ["parser.token_mappings"] =
        "parsers.board_data.internal.lex.token_mappings",
}

function M.print(key)
    local path = MAP[key]
    assert(path, "unknown alias: " .. tostring(key))

    local mod = require(path)
    assert(type(mod) == "table", "invalid alias module: " .. key)

    Printer.print("ALIAS: " .. key, mod)
end

function M.list()
    local out = {}
    for k in pairs(MAP) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

return M
