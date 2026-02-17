-- tools/struct/contract.lua

local Printer = require("tools.struct._printer")

----------------------------------------------------------------
-- LSP Literal Keys
----------------------------------------------------------------

---@alias ContractKey
---| "ledger.controller"
---| "model.order.controller"
---| "model.board.controller"
---| "model.allocations.controller"
---| "classify.controller"
---| "order_context.controller"
---| "format.controller"
---| "io.controller"
---| "parsers.controller"
---| "parsers.raw_text.controller"
---| "parsers.board_data.controller"
---| "parsers.text_engine.controller"

local M = {}

----------------------------------------------------------------
-- Controller Map
----------------------------------------------------------------

---@type table<ContractKey, string>
local MAP = {

    ----------------------------------------------------------------
    -- DOMAIN
    ----------------------------------------------------------------
    ["ledger.controller"] =
        "core.domain.ledger.controller",

    ----------------------------------------------------------------
    -- MODELS
    ----------------------------------------------------------------
    ["model.order.controller"] =
        "core.model.order.controller",

    ["model.board.controller"] =
        "core.model.board.controller",

    ["model.allocations.controller"] =
        "core.model.allocations.controller",

    ----------------------------------------------------------------
    -- CLASSIFY
    ----------------------------------------------------------------
    ["classify.controller"] =
        "classify.controller",

    ----------------------------------------------------------------
    -- ORDER CONTEXT
    ----------------------------------------------------------------
    ["order_context.controller"] =
        "order_context.controller",

    ----------------------------------------------------------------
    -- FORMAT
    ----------------------------------------------------------------
    ["format.controller"] =
        "format.controller",

    ----------------------------------------------------------------
    -- IO
    ----------------------------------------------------------------
    ["io.controller"] =
        "io.controller",

    ----------------------------------------------------------------
    -- PARSERS (ROOT)
    ----------------------------------------------------------------
    ["parsers.controller"] =
        "parsers.controller",

    ----------------------------------------------------------------
    -- PARSER SUBDOMAINS
    ----------------------------------------------------------------
    ["parsers.raw_text.controller"] =
        "parsers.raw_text.controller",

    ["parsers.board_data.controller"] =
        "parsers.board_data.controller",

    ["parsers.text_engine.controller"] =
        "parsers.pipelines.text_engine.controller",
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param key ContractKey
function M.print(key)
    local path = MAP[key]
    if not path then
        print("unknown contract:", key)
        return
    end

    local ok, mod = pcall(require, path)
    if not ok then
        print("failed loading:", path)
        return
    end

    if type(mod.CONTRACT) ~= "table" then
        print("no CONTRACT table in:", key)
        return
    end

    Printer.print_contract(key, mod.CONTRACT)
end

---@return ContractKey[]
function M.list()
    local out = {}
    for k in pairs(MAP) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

return M
