-- parsers/board_data/rules/chunk_implicit.lua
--
-- Chunk-scoped implicit rules
-- PURPOSE:
--   • Infer meaning using neighboring chunk context
--   • Lower confidence, positional heuristics

local H = require("parsers.board_data.rules.helpers")

local Rules = {}

-- Leading standalone number is count only if next chunk looks like dimensions
Rules[#Rules + 1] = {
    name      = "chunk_leading_standalone_count",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.85,
    explicit  = false,
    match = function(c, ctx)
        if c.id ~= 1 then return false end
        if not H.chunk_is_standalone_num(c) then return false end
        return H.chunk_looks_like_dim_chain(ctx.chunks[2])
    end,
    evaluate = function(c)
        return { value = H.chunk_num_value(c) }
    end,
}

-- Trailing standalone number is count only if previous chunk looks like dimensions
Rules[#Rules + 1] = {
    name      = "chunk_trailing_standalone_count",
    scope     = "chunk",
    slot      = "count",
    certainty = 0.85,
    explicit  = false,
    match = function(c, ctx)
        local last = ctx.chunks[#ctx.chunks]
        if c.id ~= last.id then return false end
        if not H.chunk_is_standalone_num(c) then return false end
        return H.chunk_looks_like_dim_chain(ctx.chunks[#ctx.chunks - 1])
    end,
    evaluate = function(c)
        return { value = H.chunk_num_value(c) }
    end,
}

return Rules
