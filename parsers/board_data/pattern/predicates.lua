-- parsers/board_data/pattern/predicates.lua

local P = {}

----------------------------------------------------------------
-- Basic token predicates
----------------------------------------------------------------

function P.num()
    return function(t)
        return t.traits and t.traits.numeric
    end
end

function P.ws()
    return function(t)
        return t.lex == "ws"
    end
end

function P.tag()
    return function(t)
        return t.labels and t.labels.tag_candidate
    end
end

----------------------------------------------------------------
-- Separator predicates
----------------------------------------------------------------

function P.sep_prefix()
    return function(t)
        return t.labels and t.labels.prefix_separator
    end
end

function P.sep_infix()
    return function(t)
        return t.labels and t.labels.infix_separator
    end
end

function P.hard_infix()
    return function(t)
        return t.labels and t.labels.infix_separator == true
    end
end

----------------------------------------------------------------
-- Unit predicates
----------------------------------------------------------------

function P.unit(kind)
    return function(t)
        return t.traits
           and t.traits.unit_candidate
           and t.traits.unit_kind == kind
    end
end

function P.postfix_unit(kind)
    return function(t)
        return t.labels
           and t.labels.postfix_unit
           and t.traits
           and t.traits.unit_kind == kind
    end
end

function P.prefix_unit(kind)
    return function(t)
        return t.traits
           and t.traits.unit_candidate
           and t.traits.unit_kind == kind
    end
end

----------------------------------------------------------------
-- Chunk predicates (mechanical only)
----------------------------------------------------------------

-- Token is the only token in its chunk
function P.standalone()
    return function(t)
        return t.chunk_size == 1
    end
end

function P.standalone_num()
    return function(t)
        return t.chunk_size == 1
           and t.traits
           and t.traits.numeric
    end
end

-- Token is at the start of its chunk
function P.chunk_start()
    return function(t)
        return t.chunk_index == 1
    end
end

-- Token is at the end of its chunk
function P.chunk_end()
    return function(t)
        return t.chunk_index == t.chunk_size
    end
end

-- Chunk has more than one token
function P.chunk_multi()
    return function(t)
        return t.chunk_size and t.chunk_size > 1
    end
end

----------------------------------------------------------------
-- Chunk-relative positional predicates
----------------------------------------------------------------

-- Token is in the first non-ws chunk
function P.first_chunk()
    return function(t)
        return t.chunk_id == 1
    end
end

-- Token is in the last non-ws chunk
function P.last_chunk(tokens)
    return function(t)
        if not tokens then return false end
        local max = 0
        for _, tok in ipairs(tokens) do
            if tok.chunk_id and tok.chunk_id > max then
                max = tok.chunk_id
            end
        end
        return t.chunk_id == max
    end
end

-- Token's chunk is immediately before another chunk
function P.chunk_before(pred)
    return function(t, _, tokens)
        if not tokens or not t.chunk_id then return false end
        local target = t.chunk_id + 1
        for _, tok in ipairs(tokens) do
            if tok.chunk_id == target and pred(tok) then
                return true
            end
        end
        return false
    end
end

-- Token's chunk is immediately after another chunk
function P.chunk_after(pred)
    return function(t, _, tokens)
        if not tokens or not t.chunk_id then return false end
        local target = t.chunk_id - 1
        for _, tok in ipairs(tokens) do
            if tok.chunk_id == target and pred(tok) then
                return true
            end
        end
        return false
    end
end

----------------------------------------------------------------
-- Combinators
----------------------------------------------------------------

function P.any(...)
    local preds = { ... }
    return function(t, i, tokens)
        for _, p in ipairs(preds) do
            if p(t, i, tokens) then
                return true
            end
        end
        return false
    end
end

----------------------------------------------------------------
-- Whitespace convenience alias
----------------------------------------------------------------

function P.maybe_ws()
    return P.ws()
end

return P
