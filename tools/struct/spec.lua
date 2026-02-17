-- tools/struct/spec.lua

local Printer = require("tools.struct._printer")

----------------------------------------------------------------
-- LSP Literal Keys
----------------------------------------------------------------

---@alias SpecKey
---| "order_context"
---| "format.shape"
---| "format.parser_gate"

local M = {}

----------------------------------------------------------------
-- Spec Map
----------------------------------------------------------------

---@type table<SpecKey, string>
local MAP = {

    ----------------------------------------------------------------
    -- ORDER CONTEXT
    ----------------------------------------------------------------
    ["order_context"] =
        "order_context.internal.spec",

    ----------------------------------------------------------------
    -- FORMAT VALIDATION SPECS
    ----------------------------------------------------------------
    ["format.shape"] =
        "format.validate.shape",

    ["format.parser_gate"] =
        "format.validate.parser_gate",
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param key SpecKey
function M.print(key)
    local path = MAP[key]
    if not path then
        print("unknown spec:", key)
        return
    end

    local ok, mod = pcall(require, path)
    if not ok then
        print("failed loading:", path)
        return
    end

    if type(mod) ~= "table" then
        print("invalid spec module:", key)
        return
    end

    Printer.print_spec(key, mod)
end

---@return SpecKey[]
function M.list()
    local out = {}
    for k in pairs(MAP) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

return M
