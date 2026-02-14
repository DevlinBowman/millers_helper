-- parsers/board_data/controller.lua
--
-- Public control surface for board_data domain.
-- PURPOSE:
--   • Provide explicit orchestration entrypoints
--   • Compose lex → chunk → attribute → resolve pipeline
--   • Return canonical parser state

local Tokenize      = require("parsers.board_data.lex.tokenize")
local ChunkBuilder  = require("parsers.board_data.chunk.chunk_builder")
local ChunkCondense = require("parsers.board_data.chunk.chunk_condense")
local Attribution   = require("parsers.board_data.attribute_attribution")
local Rules         = require("parsers.board_data.rules")
local Resolver      = require("parsers.board_data.claims.claim_resolver")

local Controller = {}

----------------------------------------------------------------
-- Full parse (single line)
----------------------------------------------------------------

---@param raw string
---@param opts table|nil
---@return table result
function Controller.parse_line(raw, opts)
    assert(type(raw) == "string", "Controller.parse_line(): raw string required")

    opts = opts or {}

    -- ----------------------------------------
    -- Lexical layer
    -- ----------------------------------------
    local tokens = Tokenize.run(raw)

    -- ----------------------------------------
    -- Chunk layer
    -- ----------------------------------------
    local chunks = ChunkBuilder.build(tokens)

    if opts.condense == true then
        chunks = ChunkCondense.run(tokens, chunks, {})
    end

    -- ----------------------------------------
    -- Attribution
    -- ----------------------------------------
    local claims = Attribution.run({
        tokens = tokens,
        chunks = chunks,
    }, Rules)

    local resolved, picked = Resolver.resolve(claims)

    return {
        tokens   = tokens,
        chunks   = chunks,
        claims   = claims,
        resolved = resolved,
        picked   = picked,
    }
end

return Controller
