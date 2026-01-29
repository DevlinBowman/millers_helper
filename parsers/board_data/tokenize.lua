-- parsers/board_data/tokenize.lua
--
-- Vocabulary-driven tokenizer
-- PURPOSE:
--   • Lossless lexical tokenization
--   • Whitespace-preserving
--   • Vocabulary-driven classification
--   • NO inference
--   • NO board logic

local TokenMap = require("parsers.board_data.token_mappings")

local Tokenize = {}

----------------------------------------------------------------
-- Lexer rules (ordered, authoritative)
----------------------------------------------------------------

local LEX_RULES = {
    -- ----------------------------------------
    -- Whitespace (lexical, first-class)
    -- ----------------------------------------
    { kind = TokenMap.KINDS.WS,     pattern = "^%s+" },

    -- ----------------------------------------
    -- Operators
    -- ----------------------------------------
    { kind = TokenMap.KINDS.OP,     pattern = "^::" },
    { kind = TokenMap.KINDS.OP,     pattern = "^=" },
    { kind = TokenMap.KINDS.OP,     pattern = "^:" },

    -- ----------------------------------------
    -- Separators
    -- ----------------------------------------
    { kind = TokenMap.KINDS.SEP,    pattern = "^by%f[%W]" },
    { kind = TokenMap.KINDS.SEP,    pattern = "^[xX*@]" },

    -- ----------------------------------------
    -- Numbers
    -- ----------------------------------------
    { kind = TokenMap.KINDS.NUMBER, pattern = "^%d+/%d+" },
    { kind = TokenMap.KINDS.NUMBER, pattern = "^%d*%.%d+" },
    { kind = TokenMap.KINDS.NUMBER, pattern = "^%d+" },

    -- ----------------------------------------
    -- Words
    -- ----------------------------------------
    { kind = TokenMap.KINDS.WORD,   pattern = "^[A-Za-z][A-Za-z0-9]*" },

    -- ----------------------------------------
    -- Symbols (punctuation, quotes, etc)
    -- ----------------------------------------
    { kind = "symbol",              pattern = "^[\"']" },
}

----------------------------------------------------------------
-- Tokenize
----------------------------------------------------------------

---@param raw string
---@return table[] tokens
function Tokenize.run(raw)
    assert(type(raw) == "string", "Tokenize.run(): raw string required")

    local tokens = {}
    local index  = 1
    local pos    = 1
    local len    = #raw

    while pos <= len do
        local slice  = raw:sub(pos)
        local matched = false

        for _, rule in ipairs(LEX_RULES) do
            local lexeme = slice:match(rule.pattern)
            if lexeme then
                matched = true

                local token = {
                    index = index,
                    raw   = lexeme,
                    kinds = {},
                    meta  = {},
                }

                index = index + 1
                pos   = pos + #lexeme

                -- ----------------------------------------
                -- Primary kind (from lexer rule)
                -- ----------------------------------------
                token.kinds[rule.kind] = true

                -- ----------------------------------------
                -- Whitespace metadata
                -- ----------------------------------------
                if rule.kind == TokenMap.KINDS.WS then
                    token.meta.len = #lexeme
                    tokens[#tokens + 1] = token
                    break
                end

                local lower = lexeme:lower()

                -- ----------------------------------------
                -- Secondary classification (TokenMap)
                -- ----------------------------------------

                if TokenMap.is_operator(lexeme) then
                    token.kinds.op = true
                end

                if TokenMap.is_separator(lexeme) then
                    token.kinds.sep = true
                end

                if TokenMap.is_unit(lexeme) then
                    token.kinds.unit = true
                end

                local tag = TokenMap.normalize_tag(lexeme)
                if tag then
                    token.kinds.tag = true
                    token.meta.tag = tag
                end

                for name, pattern in pairs(TokenMap.NUMERIC.patterns) do
                    if lexeme:match(pattern) then
                        token.kinds.number = true
                        token.meta.numeric_form = name
                        break
                    end
                end

                if TokenMap.NUMERIC.words[lower] then
                    token.kinds.number = true
                    token.meta.numeric_word = true
                    token.meta.value = TokenMap.NUMERIC.words[lower]
                end

                tokens[#tokens + 1] = token
                break
            end
        end

        if not matched then
            error("Tokenizer stalled at: " .. slice)
        end
    end

    return tokens
end

----------------------------------------------------------------
-- Human-readable token formatter (inspection only)
----------------------------------------------------------------

---@param tokens table[]
---@return string lexeme_view
---@return string kind_view
function Tokenize.format_tokens(tokens)
    assert(type(tokens) == "table", "format_tokens(): tokens must be table")

    local lex_out  = {}
    local kind_out = {}

    local function kind_code(t)
        if t.kinds.ws     then return "ws"   end
        if t.kinds.number then return "num"  end
        if t.kinds.sep    then return "sep"  end
        if t.kinds.op     then return "op"   end
        if t.kinds.unit   then return "unit" end
        if t.kinds.tag    then return "tag"  end
        if t.kinds.word   then return "w"    end
        return "?"
    end

    for _, t in ipairs(tokens) do
        if t.kinds.ws then
            -- expand whitespace one-for-one
            for _ = 1, t.meta.len do
                lex_out[#lex_out + 1]  = "[ ]"
                kind_out[#kind_out + 1] = "[ws]"
            end
        else
            lex_out[#lex_out + 1]  = "[" .. t.raw .. "]"
            kind_out[#kind_out + 1] = "[" .. kind_code(t) .. "]"
        end
    end

    return table.concat(lex_out), table.concat(kind_out)
end

return Tokenize
