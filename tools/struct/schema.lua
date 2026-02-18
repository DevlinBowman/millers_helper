-- tools/struct/schema.lua

local Printer = require("tools.struct._printer")

---@alias SchemaKey
---| "model.board"
---| "model.order"
---| "model.allocations"
---| "ledger.transaction"
---| "classify"

local M = {}

---@type table<SchemaKey, string>
local MAP = {
    ["model.board"]        = "core.model.board.internal.schema",
    ["model.order"]        = "core.model.order.internal.schema",
    ["model.allocations"]  = "core.model.allocations.internal.schema",
    ["ledger.transaction"] = "core.domain.ledger.internal.schema",
    ["classify"]           = "classify.internal.schema",
}

---@param key SchemaKey
function M.print(key)
    local path = MAP[key]
    if not path then
        print("unknown schema:", key)
        return
    end

    local ok, mod = pcall(require, path)
    if not ok then
        print("failed loading schema:", path)
        return
    end

    if type(mod) ~= "table" then
        print("schema module did not return a table:", path)
        return
    end

    Printer.print_schema(key, mod.fields or {})
end

---@return SchemaKey[]
function M.list()
    local out = {}
    for k in pairs(MAP) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

return M
