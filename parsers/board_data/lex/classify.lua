-- parsers/board_data/lex/classify.lua
--
-- Context-free intrinsic classification
-- PURPOSE:
--   • Attach vocabulary traits to lexed tokens
--   • NO neighbor context
--   • NO consumption
--   • NO parsing or reduction

local TokenMap = require("parsers.board_data.lex.token_mappings")

local Classify = {}

---@param tokens table[]
---@return table[] tokens
function Classify.run(tokens)
    assert(type(tokens) == "table", "Classify.run(): tokens must be table")

    for _, t in ipairs(tokens) do
        t.traits = t.traits or {}

        -- ----------------------------------------
        -- Numeric tokens
        -- ----------------------------------------
        if t.lex == TokenMap.LEX.NUMBER then
            t.traits.numeric = true

            for name, pattern in pairs(TokenMap.NUMERIC.patterns) do
                if t.raw:match(pattern) then
                    t.traits.numeric_form = name
                    break
                end
            end

        -- ----------------------------------------
        -- Word tokens
        -- ----------------------------------------
        elseif t.lex == TokenMap.LEX.WORD then
            local lower = t.raw:lower()

            -- numeric words ("two", "ten", etc)
            if TokenMap.NUMERIC.words[lower] then
                t.traits.numeric = true
                t.traits.numeric_word = true
                t.traits.numeric_value = TokenMap.NUMERIC.words[lower]
            end

            -- separator candidates (x, by, *, etc)
            if TokenMap.is_separator_candidate(t.raw) then
                t.traits.separator_candidate = true
            end

            -- unit candidates
            local uk = TokenMap.unit_kind(t.raw)
            if uk then
                t.traits.unit_candidate = true
                t.traits.unit_kind = uk -- "length" | "count"
            end

            -- tag candidates
            local canon = TokenMap.normalize_tag(t.raw)
            if canon then
                t.traits.tag_candidate = true
                t.traits.tag_canon = canon

                if TokenMap.is_strict_tag_letter(t.raw) then
                    t.traits.tag_strict = true
                end
            end

        -- ----------------------------------------
        -- Operators
        -- ----------------------------------------
        elseif t.lex == TokenMap.LEX.OP then
            if TokenMap.is_operator(t.raw) then
                t.traits.operator = true
            end
        end
    end

    return tokens
end

return Classify
