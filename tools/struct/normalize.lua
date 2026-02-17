-- tools/struct/normalize.lua

local Printer = require("tools.struct._printer")

---@alias NormalizeKey
---| "classify.normalize"
---| "format.clean"
---| "model.board.normalize"

local M = {}

local MAP = {
    ["classify.normalize"] =
        "classify.internal.normalize",

    ["format.clean"] =
        "format.normalize.clean",

    ["model.board.normalize"] =
        "core.model.board.internal.normalize",
}

function M.print(key)
    local path = MAP[key]
    assert(path, "unknown normalize: " .. tostring(key))

    local mod = require(path)
    assert(type(mod) == "table", "normalize module invalid: " .. key)

    Printer.print("NORMALIZE: " .. key, mod)
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
