-- parsers/pipelines/text_engine/internal/stable_spans.lua
--
-- Stable span utilities
-- EXACT CONTRACT:
--   • Picked claims with certainty >= threshold OR explicit=true
--   • Stable spans act as HARD BARRIERS
--   • Used by repair gating and condensation

local StableSpans = {}

local DEFAULT_THRESHOLD = 0.95

----------------------------------------------------------------
-- Collect stable spans (EXACT original semantics)
----------------------------------------------------------------

function StableSpans.collect(record, threshold)
    threshold = threshold or DEFAULT_THRESHOLD
    record._stable_spans = {}

    for _, p in ipairs(record._picked or {}) do
        if p
            and p.span
            and (
                p.explicit == true
                or (p.certainty and p.certainty >= threshold)
            )
        then
            record._stable_spans[#record._stable_spans + 1] = {
                field     = p.field,
                span      = { from = p.span.from, to = p.span.to },
                certainty = p.certainty,
                rule      = p.rule,
            }
        end
    end

    return record._stable_spans
end

----------------------------------------------------------------
-- Token-level query
----------------------------------------------------------------

function StableSpans.token_is_stable(token, stable_spans)
    if not (token and token.index and stable_spans) then
        return false
    end

    for _, s in ipairs(stable_spans) do
        if token.index >= s.span.from and token.index <= s.span.to then
            return true
        end
    end

    return false
end

----------------------------------------------------------------
-- Chunk-level query
----------------------------------------------------------------

function StableSpans.chunk_overlaps(chunk, stable_spans)
    if not (chunk and chunk.span and stable_spans) then
        return false
    end

    for _, s in ipairs(stable_spans) do
        local a = chunk.span
        local b = s.span
        if not (a.to < b.from or b.to < a.from) then
            return true
        end
    end

    return false
end

return StableSpans
