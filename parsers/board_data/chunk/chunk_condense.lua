-- parsers/board_data/chunk/chunk_condense.lua
--
-- PURPOSE:
--   • Attempt to reduce ambiguity caused by overspacing
--   • Merge adjacent chunks when that merge is "reasonable"
--   • Used as a failsafe when resolution misses required dims

local Condense = {}

local function clone_chunk_like(id, a, b)
    local tokens = {}
    for _, t in ipairs(a.tokens) do tokens[#tokens + 1] = t end
    for _, t in ipairs(b.tokens) do tokens[#tokens + 1] = t end

    local merged = {
        id     = id,
        tokens = tokens,
        span   = { from = a.span.from, to = b.span.to },

        has_num   = (a.has_num or b.has_num),
        has_unit  = (a.has_unit or b.has_unit),
        has_tag   = (a.has_tag or b.has_tag),
        has_infix = (a.has_infix or b.has_infix),
    }

    return merged
end

local function is_standalone_numeric(chunk)
    return chunk
       and chunk.size == 1
       and chunk.has_num
end

local function looks_like_dimension_chain_chunk(chunk)
    -- cheap: needs infix separators and 3 numbers inside
    if not (chunk and chunk.has_infix and chunk.has_num) then return false end
    local num_ct = 0
    for _, t in ipairs(chunk.tokens) do
        if t.traits and t.traits.numeric then num_ct = num_ct + 1 end
    end
    return num_ct >= 3
end

local function merge_reasonable(left, right)
    -- Don't merge count-like singleton into a dimension chain chunk
    if is_standalone_numeric(left) and looks_like_dimension_chain_chunk(right) then
        return false
    end
    if is_standalone_numeric(right) and looks_like_dimension_chain_chunk(left) then
        return false
    end

    -- Avoid merging units into unrelated chains (keeps "10pcs" intact)
    if left.has_unit ~= right.has_unit and (left.has_unit or right.has_unit) then
        -- allow merge only if one side is a singleton 'x' separator chunk
        local function is_single_sep_x(c)
            return c and c.size == 1 and c.tokens[1]
               and c.tokens[1].labels and c.tokens[1].labels.separator_candidate
        end
        if not (is_single_sep_x(left) or is_single_sep_x(right)) then
            return false
        end
    end

    return true
end

local function starts_with_infix(chunk)
    local t = chunk.tokens[1]
    return t and t.labels and t.labels.infix_separator
end

---@param tokens table[]
---@param chunks table[]
---@return table condensed_chunks
function Condense.run(tokens, chunks)
    assert(type(tokens) == "table", "Condense.run(): tokens must be table")
    assert(type(chunks) == "table", "Condense.run(): chunks must be table")

    -- Ensure chunk.size exists
    for _, c in ipairs(chunks) do
        c.size = c.size or #c.tokens
    end

    local out = {}
    local i   = 1
    local id  = 0

    while i <= #chunks do
        local cur = chunks[i]
        id = id + 1

        -- Greedy merge forward while reasonable
        local merged = cur
        local j = i + 1
        while j <= #chunks do
            local nxt = chunks[j]
            merged.size = merged.size or #merged.tokens
            nxt.size = nxt.size or #nxt.tokens

            if not merge_reasonable(merged, nxt) then
                break
            end

            -- Merge
            merged = clone_chunk_like(id, merged, nxt)
            merged.size = #merged.tokens
            j = j + 1
        end

        merged.id = id
        out[#out + 1] = merged
        i = j
    end

    -- Re-annotate tokens with new chunk ids/sizes/indexes
    for _, c in ipairs(out) do
        c.size = #c.tokens
        for idx, t in ipairs(c.tokens) do
            t.chunk_id    = c.id
            t.chunk_size  = c.size
            t.chunk_index = idx
        end
    end

    return out
end

return Condense
