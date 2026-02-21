-- parsers/board_data/pipelines/parse_line.lua

local Registry = require("platform.parsers.board_data.registry")

local ParseLinePipeline = {}

function ParseLinePipeline.run(raw, opts)
    opts = opts or {}

    -- Lex
    local tokens = Registry.lex.tokenize.run(raw)

    -- Chunk
    local chunks = Registry.chunk.build.build(tokens)

    if opts.condense then
        chunks = Registry.chunk.condense.run(
            tokens,
            chunks,
            {}
        )
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
