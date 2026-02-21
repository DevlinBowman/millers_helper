-- parsers/board_data/internal/rules/helpers.lua
--
-- Shared helper functions for chunk-based rules
-- PURPOSE:
--   • Centralize reusable chunk inspection logic
--   • Keep rules declarative and readable
--   • No side effects, no rule registration

local H = {}

function H.chunk_num_value(chunk)
    if not (chunk and chunk.tokens and chunk.tokens[1]) then return nil end
    local t = chunk.tokens[1]
    if t.traits and t.traits.numeric then
        return tonumber(t.raw)
    end
    return nil
end

function H.chunk_is_standalone_num(chunk)
    return chunk and chunk.size == 1 and chunk.has_num
end

function H.chunk_is_prefix_x_count(chunk)
    if not (chunk and chunk.size == 2) then return false end
    local a = chunk.tokens[1]
    local b = chunk.tokens[2]
    return a and a.labels and a.labels.prefix_separator
       and b and b.traits and b.traits.numeric
end

function H.chunk_looks_like_dim_chain(chunk)
    if not (chunk and chunk.has_infix) then return false end
    local num_ct = 0
    for _, t in ipairs(chunk.tokens) do
        if t.traits and t.traits.numeric then
            num_ct = num_ct + 1
        end
    end
    return num_ct >= 3
end

return H
