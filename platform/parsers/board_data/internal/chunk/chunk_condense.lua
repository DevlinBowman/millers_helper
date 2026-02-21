-- parsers/board_data/internal/chunk/chunk_condense.lua
--
-- PURPOSE:
--   • Reduce ambiguity caused by overspacing
--   • Merge adjacent chunks when mechanically safe
--   • NEVER cross stable (committed) spans
--   • Defer ALL illegal-merge logic to chunk_ignore
--
-- NON-RESPONSIBILITIES:
--   • No semantic inference
--   • No certainty logic
--   • No attribute assignment
--   • No rule awareness

local Ignore = require("platform.parsers.board_data.internal.chunk.chunk_ignore")

local Condense = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function spans_overlap(a, b)
    if not a or not b then return false end
    return not (a.to < b.from or b.to < a.from)
end

local function chunk_overlaps_stable(chunk, stable_spans)
    if not chunk or not stable_spans then return false end
    for _, s in ipairs(stable_spans) do
        if spans_overlap(chunk.span, s.span) then
            return true
        end
    end
    return false
end

local function clone_chunk_like(id, a, b)
    local tokens = {}
    for _, t in ipairs(a.tokens) do tokens[#tokens + 1] = t end
    for _, t in ipairs(b.tokens) do tokens[#tokens + 1] = t end

    return {
        id        = id,
        tokens    = tokens,
        span      = { from = a.span.from, to = b.span.to },

        -- propagate structural flags only (no inference)
        has_num   = (a.has_num   or b.has_num),
        has_unit  = (a.has_unit  or b.has_unit),
        has_tag   = (a.has_tag   or b.has_tag),
        has_infix = (a.has_infix or b.has_infix),
    }
end

----------------------------------------------------------------
-- Merge policy
----------------------------------------------------------------

local function merge_reasonable(left, right)
    -- ------------------------------------------------------------
    -- HARD PROHIBITIONS (absolute structural invariants)
    -- ------------------------------------------------------------
    if Ignore.should_forbid_merge(left, right) then
        return false
    end

    -- ------------------------------------------------------------
    -- SOFT MECHANICAL HEURISTICS
    -- (overspacing only; never semantic)
    -- ------------------------------------------------------------

    -- Avoid merging units into unrelated chains (keeps "10 pcs" intact)
    if left.has_unit ~= right.has_unit and (left.has_unit or right.has_unit) then
        -- allow merge only if one side is a singleton separator
        local function is_single_separator(c)
            return c
               and c.size == 1
               and c.tokens[1]
               and c.tokens[1].labels
               and c.tokens[1].labels.separator_candidate
        end

        if not (is_single_separator(left) or is_single_separator(right)) then
            return false
        end
    end

    return true
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param tokens table[]
---@param chunks table[]
---@param ctx table|nil  -- { stable_spans? }
---@return table condensed_chunks
function Condense.run(tokens, chunks, ctx)
    assert(type(tokens) == "table", "Condense.run(): tokens must be table")
    assert(type(chunks) == "table", "Condense.run(): chunks must be table")

    local stable_spans = ctx and ctx.stable_spans or nil

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

        -- Start a new merged chunk
        local merged = cur
        local j = i + 1

        -- --------------------------------------------------------
        -- Greedy forward merge while:
        --   • mechanically safe
        --   • NOT crossing stable spans
        -- --------------------------------------------------------
        while j <= #chunks do
            local nxt = chunks[j]

            merged.size = merged.size or #merged.tokens
            nxt.size    = nxt.size    or #nxt.tokens

            -- Do not cross stable structure
            if stable_spans then
                if chunk_overlaps_stable(merged, stable_spans)
                   or chunk_overlaps_stable(nxt, stable_spans)
                then
                    break
                end
            end

            if not merge_reasonable(merged, nxt) then
                break
            end

            merged = clone_chunk_like(id, merged, nxt)
            merged.size = #merged.tokens
            j = j + 1
        end

        merged.id = id
        out[#out + 1] = merged
        i = j
    end

    -- ------------------------------------------------------------
    -- Re-annotate tokens with new chunk ids/sizes/indexes
    -- ------------------------------------------------------------
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
