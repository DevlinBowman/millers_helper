-- parsers/board_data/internal/attribute/attribution.lua
--
-- Attribute attribution engine
-- PURPOSE:
--   • Apply declarative rules to tokens and chunks
--   • Emit candidate claims with certainty and spans
--   • Explicitly report which tokens were touched
--   • Respect "stable spans" (committed high-certainty structure)
--
-- NON-RESPONSIBILITIES:
--   • No resolution / arbitration
--   • No mutation of tokens or chunks
--   • No structural repair
--   • No inference heuristics

local Matcher = require("parsers.board_data.internal.pattern.pattern_match")

local Attribution = {}

----------------------------------------------------------------
-- Structural classification (coverage only)
----------------------------------------------------------------

local function infer_chunk_kind(chunk)
    -- purely structural bucket, NOT semantic truth
    if chunk.has_tag and chunk.size == 1 then
        return "tag_candidate"
    end
    if chunk.has_unit and chunk.has_num then
        return "unit_num_group"
    end
    if chunk.has_infix and chunk.has_num then
        return "infix_numeric_chain"
    end
    if chunk.has_prefix_sep and chunk.has_num then
        return "prefix_sep_numeric"
    end
    if chunk.has_num and chunk.size == 1 then
        return "standalone_num"
    end
    return "unknown"
end

----------------------------------------------------------------
-- Stable span helpers
----------------------------------------------------------------

local function spans_overlap(a, b)
    if not a or not b then return false end
    return not (a.to < b.from or b.to < a.from)
end

local function span_is_stable(span, stable_spans)
    if not span or not stable_spans then return false end
    for _, s in ipairs(stable_spans) do
        if spans_overlap(span, s.span) then
            return true
        end
    end
    return false
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param ctx table   -- {
---                     tokens,
---                     chunks,
---                     stable_spans? = { { field, span, certainty, rule } }
---                   }
---@param rules table[]
---@return table claims
function Attribution.run(ctx, rules)
    assert(type(ctx) == "table", "Attribution.run(): ctx required")
    assert(type(rules) == "table", "Attribution.run(): rules required")

    local tokens       = ctx.tokens or {}
    local chunks       = ctx.chunks or {}
    local stable_spans = ctx.stable_spans

    local claims = {}

    -- ------------------------------------------------------------
    -- Coverage: structural classification for every chunk
    -- (Coverage is allowed to overlap stable spans; it is non-semantic)
    -- ------------------------------------------------------------
    for _, chunk in ipairs(chunks) do
        claims[#claims + 1] = {
            slot      = "chunk_kind",
            value     = infer_chunk_kind(chunk),
            certainty = 1.0,
            rule      = "coverage_chunk_kind",
            span      = chunk.span,
            touched   = chunk.span, -- explicit coverage
            scope     = "chunk",
            chunk_id  = chunk.id,
        }
    end

    -- ------------------------------------------------------------
    -- Rule-driven claims
    -- ------------------------------------------------------------
    for _, rule in ipairs(rules) do
        if rule.scope == "chunk" then
            for _, chunk in ipairs(chunks) do
                local default_span = chunk.span

                -- Do not re-attribute stable structure
                if span_is_stable(default_span, stable_spans) then
                    goto continue_chunk
                end

                if rule.match(chunk, ctx) then
                    local result = rule.evaluate(chunk, ctx)

                    if result and result.value ~= nil then
                        local slot  = result.slot_override or rule.slot
                        local span  = result.span_override or default_span

                        claims[#claims + 1] = {
                            slot      = slot,
                            value     = result.value,
                            certainty = result.certainty or rule.certainty or 0.5,
                            rule      = rule.name,
                            span      = span,
                            touched   = span, -- explicit attribution footprint
                            scope     = "chunk",
                            chunk_id  = chunk.id,
                        }
                    end
                end

                ::continue_chunk::
            end

        elseif rule.scope == "token" then
            for i = 1, #tokens do
                local match = Matcher.match_at(tokens, i, rule.pattern)
                if match then
                    local span = { from = i, to = i + #rule.pattern - 1 }

                    -- Do not re-attribute stable structure
                    if span_is_stable(span, stable_spans) then
                        goto continue_token
                    end

                    local result = rule.evaluate(match, {
                        tokens      = tokens,
                        start_index = i,
                    })

                    if result and result.value ~= nil then
                        local slot = result.slot_override or rule.slot
                        local out_span = result.span_override or span

                        claims[#claims + 1] = {
                            slot      = slot,
                            value     = result.value,
                            certainty = result.certainty or rule.certainty or 0.5,
                            rule      = rule.name,
                            span      = out_span,
                            touched   = out_span, -- explicit attribution footprint
                            scope     = "token",
                        }
                    end
                end

                ::continue_token::
            end

        else
            error("Rule '" .. tostring(rule.name) .. "' is missing scope")
        end
    end

    return claims
end

return Attribution
