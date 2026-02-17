-- tools/struct/parser.lua

local Printer = require("tools.struct._printer")

---@alias ParserKey
---| "board.lex.mappings"
---| "board.lex.predicates"
---| "board.pattern.predicates"
---| "board.rules"
---| "board.chunk.predicates"
---| "board.chunk.ignore"
---| "board.claim.resolver"
---| "board.claim.format"
---| "board.claim.view"
---| "text_engine.preprocess"
---| "text_engine.repair_gate"
---| "text_engine.stable_spans"
---| "text_engine.token_usage"

local M = {}

local MAP = {
    ["board.lex.mappings"] =
        "parsers.board_data.internal.lex.token_mappings",

    ["board.lex.predicates"] =
        "parsers.board_data.internal.pattern.predicates",

    ["board.pattern.predicates"] =
        "parsers.board_data.internal.pattern.predicates",

    ["board.rules"] =
        "parsers.board_data.internal.rules",

    ["board.chunk.predicates"] =
        "parsers.board_data.internal.chunk.chunk_predicates",

    ["board.chunk.ignore"] =
        "parsers.board_data.internal.chunk.chunk_ignore",

    ["board.claim.resolver"] =
        "parsers.board_data.internal.claims.claim_resolver",

    ["board.claim.format"] =
        "parsers.board_data.internal.claims.format_claims",

    ["board.claim.view"] =
        "parsers.board_data.internal.claims.claim_view",

    ["text_engine.preprocess"] =
        "parsers.pipelines.text_engine.internal.preprocess",

    ["text_engine.repair_gate"] =
        "parsers.pipelines.text_engine.internal.repair_gate",

    ["text_engine.stable_spans"] =
        "parsers.pipelines.text_engine.internal.stable_spans",

    ["text_engine.token_usage"] =
        "parsers.pipelines.text_engine.internal.token_usage",
}

function M.get(parser_key)
    local module_path = MAP[parser_key]
    assert(module_path, "unknown parser key: " .. tostring(parser_key))

    local module = require(module_path)
    assert(type(module) == "table", "parser module invalid: " .. module_path)

    return module
end

function M.print(parser_key)
    local struct = M.get(parser_key)
    Printer.print("PARSER: " .. parser_key, struct)
end

function M.keys()
    local keys = {}
    for k in pairs(MAP) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

-- alias for uniform API
M.list = M.keys

return M
