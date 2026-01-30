-- parsers/board_data/lex/tokenize.lua
--
-- Tokenization facade
-- PURPOSE:
--   • Preserve existing API: Tokenize.run(raw)
--   • Compose layered pipeline:
--       1) Lexer (lossless)
--       2) Classify (traits)
--       3) Labeler (contextual labels)
--   • Provide inspection formatting helpers

local TokenMap  = require("parsers.board_data.lex.token_mappings")
local Lexer     = require("parsers.board_data.lex.lexer")
local Classify  = require("parsers.board_data.lex.classify")
local Labeler   = require("parsers.board_data.lex.labeler")
local ReduceFraction = require("parsers.board_data.lex.reduce_fractional_number")

local Tokenize = {}

---@param raw string
---@return table[] tokens
function Tokenize.run(raw)
    assert(type(raw) == "string", "Tokenize.run(): raw string required")

    local tokens = Lexer.run(raw)
    Classify.run(tokens)
    Labeler.run(tokens)

    -- ONLY destructive pass in this pipeline
    tokens = ReduceFraction.run(tokens)

    return tokens
end

----------------------------------------------------------------
-- Human-readable token formatter (inspection only)
----------------------------------------------------------------

local function label_code(t)
    -- Prefer labels that are most semantically useful for debugging reduction.
    if t.lex == TokenMap.LEX.WS then return "ws" end
    if t.labels and t.labels.tag_certain then return "tag!" end
    if t.labels and t.labels.postfix_unit_length then return "u.len" end
    if t.labels and t.labels.postfix_unit_count then return "u.ct" end
    if t.labels and t.labels.infix_separator then return "sep.infix" end
    if t.labels and t.labels.prefix_separator then return "sep.prefix" end

    -- fall back to traits
    if t.traits and t.traits.unit_candidate then return "unit" end
    if t.traits and t.traits.tag_candidate then return "tag" end
    if t.traits and t.traits.separator_candidate then return "sep?" end
    if t.traits and t.traits.numeric then return "num" end

    -- fall back to lex
    return t.lex or "?"
end

---@param tokens table[]
---@return string lexeme_view
---@return string label_view
function Tokenize.format_tokens(tokens)
    assert(type(tokens) == "table", "Tokenize.format_tokens(): tokens must be table")

    local lex_out   = {}
    local label_out = {}

    for _, t in ipairs(tokens) do
        if t.lex == TokenMap.LEX.WS then
            for _ = 1, t.meta.len do
                lex_out[#lex_out + 1] = "[ ]"
                label_out[#label_out + 1] = "[ws]"
            end
        else
            lex_out[#lex_out + 1] = "[" .. t.raw .. "]"
            label_out[#label_out + 1] = "[" .. label_code(t) .. "]"
        end
    end

    return table.concat(lex_out), table.concat(label_out)
end

return Tokenize
