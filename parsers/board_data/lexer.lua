-- parsers/board_data/lexer.lua
--
-- Domain-aware lexical segmentation
-- PURPOSE:
--   • Lossless tokenization
--   • Preserve whitespace and order
--   • Split alphanumeric runs into atomic domain tokens
--   • NO semantic meaning
--   • NO reduction

local TokenMap = require("parsers.board_data.token_mappings")

local Lexer = {}

----------------------------------------------------------------
-- Coarse lexer rules
----------------------------------------------------------------

local COARSE_RULES = {
    { lex = TokenMap.LEX.WS,     pattern = "^%s+" },

    -- operators first
    { lex = TokenMap.LEX.OP,     pattern = "^::" },
    { lex = TokenMap.LEX.OP,     pattern = "^=" },
    { lex = TokenMap.LEX.OP,     pattern = "^:" },

    -- alphanumeric runs (to be split further)
    { lex = "alnum",             pattern = "^[A-Za-z0-9]+" },

    -- any remaining single character
    { lex = TokenMap.LEX.SYMBOL, pattern = "^." },
}

----------------------------------------------------------------
-- Build longest-first vocabulary list
----------------------------------------------------------------

local VOCAB = {}

do
    -- separators
    for _, sep in ipairs(TokenMap.SEPARATORS) do
        VOCAB[#VOCAB + 1] = sep
    end

    -- units
    for _, group in pairs(TokenMap.UNITS) do
        for _, u in ipairs(group) do
            VOCAB[#VOCAB + 1] = u
        end
    end

    -- tags
    for _, variants in pairs(TokenMap.TAGS) do
        for _, v in ipairs(variants) do
            VOCAB[#VOCAB + 1] = v
        end
    end

    -- sort longest → shortest
    table.sort(VOCAB, function(a, b)
        return #a > #b
    end)
end


----------------------------------------------------------------
-- Atomic splitting of alphanumeric runs
----------------------------------------------------------------

local function split_alnum(run)
    local out = {}
    local i = 1

    while i <= #run do
        local slice = run:sub(i)

        -- number (fraction first)
        local m =
            slice:match("^%d+/%d+") or
            slice:match("^%d*%.%d+") or
            slice:match("^%d+")

        if m then
            out[#out + 1] = {
                raw = m,
                lex = TokenMap.LEX.NUMBER,
            }
            i = i + #m
            goto continue
        end

        -- vocabulary match (longest-first)
        for _, v in ipairs(VOCAB) do
            if slice:lower():sub(1, #v) == v then
                out[#out + 1] = {
                    raw = slice:sub(1, #v),
                    lex = TokenMap.LEX.WORD,
                }
                i = i + #v
                goto continue
            end
        end

        -- fallback: single letter
        out[#out + 1] = {
            raw = slice:sub(1, 1),
            lex = TokenMap.LEX.WORD,
        }
        i = i + 1

        ::continue::
    end

    return out
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param raw string
---@return table[] tokens
function Lexer.run(raw)
    assert(type(raw) == "string", "Lexer.run(): raw string required")

    local tokens = {}
    local pos = 1
    local idx = 1

    while pos <= #raw do
        local slice = raw:sub(pos)
        local matched = false

        for _, rule in ipairs(COARSE_RULES) do
            local lexeme = slice:match(rule.pattern)
            if lexeme then
                matched = true
                pos = pos + #lexeme

                -- ----------------------------------------
                -- Alphanumeric runs get split
                -- ----------------------------------------
                if rule.lex == "alnum" then
                    local parts = split_alnum(lexeme)
                    for _, p in ipairs(parts) do
                        tokens[#tokens + 1] = {
                            index  = idx,
                            raw    = p.raw,
                            lex    = p.lex,
                            meta   = { len = #p.raw },
                            traits = {},
                            labels = {},
                        }
                        idx = idx + 1
                    end
                else
                    tokens[#tokens + 1] = {
                        index  = idx,
                        raw    = lexeme,
                        lex    = rule.lex,
                        meta   = { len = #lexeme },
                        traits = {},
                        labels = {},
                    }
                    idx = idx + 1
                end

                break
            end
        end

        if not matched then
            error("Lexer stalled at: " .. slice)
        end
    end

    return tokens
end

return Lexer
