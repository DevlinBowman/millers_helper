-- tools/struct/enum.lua

local Printer = require("tools.struct._printer")

----------------------------------------------------------------
-- LSP Literal Keys
----------------------------------------------------------------

---@alias EnumKey
---| "core.transaction_type"
---| "core.grade"
---| "core.use_type"

local M = {}

----------------------------------------------------------------
-- Enum Map
----------------------------------------------------------------

---@type table<EnumKey, string>
local MAP = {

    ----------------------------------------------------------------
    -- Add actual enum modules from core/enums here
    ----------------------------------------------------------------

    ["core.transaction_type"] =
        "core.enums.transaction_type",

    ["core.grade"] =
        "core.enums.grade",

    ["core.use_type"] =
        "core.enums.use_type",
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param key EnumKey
function M.print(key)
    local path = MAP[key]
    if not path then
        print("unknown enum:", key)
        return
    end

    local ok, mod = pcall(require, path)
    if not ok then
        print("failed loading:", path)
        return
    end

    if type(mod) ~= "table" then
        print("enum module invalid:", key)
        return
    end

    print("\n============================================================")
    print("ENUM: " .. key)
    print("============================================================")

    for k, v in pairs(mod) do
        print(string.format("  %-20s = %s", tostring(k), tostring(v)))
    end

    print("============================================================\n")
end

---@return EnumKey[]
function M.list()
    local out = {}
    for k in pairs(MAP) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

return M
