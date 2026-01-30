-- parsers/board_data/chunk/chunk/chunk_builder.lua
local TokenMap = require("parsers.board_data.lex.token_mappings")

local ChunkBuilder = {}

local function finalize_chunk(chunk)
    if not chunk then return end
    chunk.size = #chunk.tokens
    for j, tok in ipairs(chunk.tokens) do
        tok.chunk_id    = chunk.id
        tok.chunk_size  = chunk.size
        tok.chunk_index = j
    end
end

function ChunkBuilder.build(tokens)
    assert(type(tokens) == "table", "ChunkBuilder.build(): tokens must be table")

    local chunks  = {}
    local current = nil
    local id      = 0

    for i, t in ipairs(tokens) do
        if t.lex == TokenMap.LEX.WS then
            finalize_chunk(current)
            current = nil
        else
            if not current then
                id = id + 1
                current = {
                    id     = id,
                    tokens = {},
                    span   = { from = i, to = i },

                    has_num   = false,
                    has_unit  = false,
                    has_tag   = false,
                    has_infix = false,
                }
                chunks[#chunks + 1] = current
            end

            current.tokens[#current.tokens + 1] = t
            current.span.to = i

            if t.traits and t.traits.numeric then current.has_num = true end
            if t.traits and t.traits.unit_candidate then current.has_unit = true end
            if t.traits and t.traits.tag_strict then current.has_tag = true end
            if t.labels and t.labels.infix_separator then current.has_infix = true end
        end
    end

    finalize_chunk(current)
    return chunks
end

function ChunkBuilder.format(chunks)
    assert(type(chunks) == "table", "ChunkBuilder.format(): chunks must be table")

    local out = {}
    for _, c in ipairs(chunks) do
        local parts = {}
        for _, t in ipairs(c.tokens) do
            parts[#parts + 1] = "[" .. tostring(t.raw) .. "]"
        end
        out[#out + 1] = "{" .. table.concat(parts, "") .. "}"
    end
    return table.concat(out, " ")
end

return ChunkBuilder
