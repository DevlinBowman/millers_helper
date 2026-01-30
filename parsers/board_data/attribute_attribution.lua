-- parsers/board_data/attribute_attribution.lua

local Matcher = require("parsers.board_data.pattern.pattern_match")

local Attribution = {}

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

---@param ctx table  -- { tokens, chunks }
---@param rules table[]
---@return table claims
function Attribution.run(ctx, rules)
    assert(type(ctx) == "table", "Attribution.run(): ctx required")
    assert(type(rules) == "table", "Attribution.run(): rules required")

    local claims = {}

    -- ------------------------------------------------------------
    -- Coverage: claim every chunk (structural bucket)
    -- ------------------------------------------------------------
    if ctx.chunks then
        for _, chunk in ipairs(ctx.chunks) do
            claims[#claims + 1] = {
                slot      = "chunk_kind",
                value     = infer_chunk_kind(chunk),
                certainty = 1.0,
                rule      = "coverage_chunk_kind",
                span      = chunk.span,
                scope     = "chunk",
                chunk_id  = chunk.id,
            }
        end
    end

    -- ------------------------------------------------------------
    -- Rule-driven claims
    -- ------------------------------------------------------------
    for _, rule in ipairs(rules) do
        if rule.scope == "chunk" then
            assert(ctx.chunks, "chunk-scoped rule requires ctx.chunks")
            for _, chunk in ipairs(ctx.chunks) do
                if rule.match(chunk, ctx) then
                    local result = rule.evaluate(chunk, ctx)
                    if result and result.value ~= nil then
                        claims[#claims + 1] = {
                            slot      = rule.slot,
                            value     = result.value,
                            certainty = result.certainty or rule.certainty or 0.5,
                            rule      = rule.name,
                            span      = chunk.span,
                            scope     = "chunk",
                            chunk_id  = chunk.id,
                        }
                    end
                end
            end

        elseif rule.scope == "token" then
            local tokens = ctx.tokens
            for i = 1, #tokens do
                local match = Matcher.match_at(tokens, i, rule.pattern)
                if match then
                    local result = rule.evaluate(match, {
                        tokens      = tokens,
                        start_index = i,
                    })
                    if result and result.value ~= nil then
                        claims[#claims + 1] = {
                            slot      = rule.slot,
                            value     = result.value,
                            certainty = result.certainty or rule.certainty or 0.5,
                            rule      = rule.name,
                            span      = { from = i, to = i + #rule.pattern - 1 },
                            scope     = "token",
                        }
                    end
                end
            end
        else
            error("Rule '" .. tostring(rule.name) .. "' is missing scope")
        end
    end

    return claims
end

return Attribution
