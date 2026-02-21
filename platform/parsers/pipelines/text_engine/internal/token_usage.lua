-- parsers/pipelines/text_engine/internal/token_usage.lua
--
-- Token usage ledger
-- EXACT CONTRACT:
--   • "Touched" = semantically evaluated
--   • coverage_chunk_kind DOES NOT COUNT

local TokenUsage = {}

----------------------------------------------------------------
-- Init
----------------------------------------------------------------

function TokenUsage.init(record)
    record._token_usage = record._token_usage or {}
    record._token_usage_by_rule = record._token_usage_by_rule or {}
end

----------------------------------------------------------------
-- Update (record touched spans)
----------------------------------------------------------------

function TokenUsage.update(record, claims)
    if type(claims) ~= "table" then return end
    TokenUsage.init(record)

    for _, c in ipairs(claims) do
        if not (c and c.rule and c.slot and c.touched) then
            goto continue
        end

        local span = c.touched
        if type(span.from) ~= "number" or type(span.to) ~= "number" then
            goto continue
        end

        -- index by rule
        local by_rule = record._token_usage_by_rule
        by_rule[c.rule] = by_rule[c.rule] or {}
        by_rule[c.rule][#by_rule[c.rule] + 1] = {
            from = span.from,
            to   = span.to,
            slot = c.slot,
        }

        for i = span.from, span.to do
            record._token_usage[i] = record._token_usage[i] or {}
            record._token_usage[i][#record._token_usage[i] + 1] = {
                rule      = c.rule,
                slot      = c.slot,
                certainty = c.certainty,
                picked    = false,
            }
        end

        ::continue::
    end
end

----------------------------------------------------------------
-- Mark picked tokens
----------------------------------------------------------------

function TokenUsage.mark_picked(record, picked)
    if type(picked) ~= "table" then return end
    TokenUsage.init(record)

    for _, p in ipairs(picked) do
        if not (p and p.rule and p.span) then
            goto continue
        end

        local from, to = p.span.from, p.span.to
        if type(from) ~= "number" or type(to) ~= "number" then
            goto continue
        end

        for i = from, to do
            local entries = record._token_usage[i]
            if entries then
                for _, e in ipairs(entries) do
                    if e.rule == p.rule then
                        e.picked = true
                    end
                end
            end
        end

        ::continue::
    end
end

----------------------------------------------------------------
-- Query helpers (EXACT semantics)
----------------------------------------------------------------

function TokenUsage.is_semantically_touched(entries)
    if type(entries) ~= "table" then
        return false
    end

    for _, e in ipairs(entries) do
        if e.rule ~= "coverage_chunk_kind" then
            return true
        end
    end

    return false
end

function TokenUsage.is_picked(entries)
    if type(entries) ~= "table" then
        return false
    end

    for _, e in ipairs(entries) do
        if e.picked then
            return true
        end
    end

    return false
end

return TokenUsage
