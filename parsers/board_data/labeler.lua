-- parsers/board_data/labeler.lua
--
-- Shallow contextual labeling (non-consuming)
-- PURPOSE:
--   • Derive "natural context" into labels
--   • Only local neighbor context (±1/±2, skipping ws)
--   • Labels are hints, not meaning
--   • NO consumption, NO reduction, NO board logic

local TokenMap = require("parsers.board_data.token_mappings")

local Labeler = {}

local function prev_non_ws(tokens, i)
    for j = i - 1, 1, -1 do
        if tokens[j].lex ~= TokenMap.LEX.WS then
            return tokens[j], j
        end
    end
    return nil, nil
end

local function next_non_ws(tokens, i)
    for j = i + 1, #tokens do
        if tokens[j].lex ~= TokenMap.LEX.WS then
            return tokens[j], j
        end
    end
    return nil, nil
end

---@param tokens table[]
---@return table[] tokens
function Labeler.run(tokens)
    assert(type(tokens) == "table", "Labeler.run(): tokens must be table")

    for i, t in ipairs(tokens) do
        t.labels = t.labels or {}

        local prev = nil
        local next = nil
        prev = (select(1, prev_non_ws(tokens, i)))
        next = (select(1, next_non_ws(tokens, i)))

        -- ----------------------------
        -- Common labels
        -- ----------------------------
        if t.lex == TokenMap.LEX.NUMBER or t.traits.numeric then
            t.labels.numeric_literal = true
        end

        -- ----------------------------
        -- Units: postfix relationship
        -- ----------------------------
        if t.traits.unit_candidate then
            t.labels.unit = true
            t.labels["unit_" .. tostring(t.traits.unit_kind)] = true

            if prev and prev.traits.numeric then
                t.labels.postfix_unit = true
                t.labels["postfix_unit_" .. tostring(t.traits.unit_kind)] = true
            end
        end

        -- ----------------------------
        -- Tags: strict standalone letters are "certain"
        -- ----------------------------
        if t.traits.tag_candidate then
            t.labels.tag_candidate = true
            t.labels["tag_" .. tostring(t.traits.tag_canon)] = true

            if t.traits.tag_strict then
                -- strict tag is considered standalone by shape (single token)
                t.labels.standalone_tag = true
                t.labels.tag_certain = true
            end

            if prev and prev.traits.numeric then
                t.labels.after_number = true
            end
        end

        -- ----------------------------
        -- Separator candidates: local context labels
        -- ----------------------------
        if t.traits.separator_candidate then
            t.labels.separator_candidate = true

            if prev and prev.traits.numeric and next and next.traits.numeric then
                t.labels.infix_separator = true
            end

            if next and next.traits.numeric and (not prev or not prev.traits.numeric) then
                t.labels.prefix_separator = true
            end

            if prev and prev.traits.numeric and (not next or not next.traits.numeric) then
                t.labels.postfix_separator = true
            end
        end
    end

    return tokens
end

return Labeler
