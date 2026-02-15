-- parsers/board_data/pipelines/parse_line.lua
--
-- Pipeline: parse a single board line
--
-- Responsibilities:
--   • Compose lex → chunk → attribute → resolve
--   • No contracts
--   • No tracing
--   • No validation

local Registry = require("parsers.board_data.registry")

local ParseLinePipeline = {}

---@param raw string
---@param opts table|nil
---@return table result
function ParseLinePipeline.run(raw, opts)
    opts = opts or {}

    -- Lex
    local tokens = Registry.lex.tokenize.run(raw)

    -- Chunk
    local chunks = Registry.chunk.build.build(tokens)

    if opts.condense == true then
        chunks = Registry.chunk.condense.run(tokens, chunks, {})
    end

    -- Attribute
    local claims = Registry.attribution.run({
        tokens = tokens,
        chunks = chunks,
    }, Registry.rules)

    -- Resolve
    local resolved, picked =
        Registry.claims.resolver.resolve(claims)

    return {
        tokens   = tokens,
        chunks   = chunks,
        claims   = claims,
        resolved = resolved,
        picked   = picked,
    }
end

return ParseLinePipeline
