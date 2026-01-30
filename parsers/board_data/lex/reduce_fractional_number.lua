-- parsers/board_data/lex/reduce_fractional_number.lua
--
-- Fractional numeric reducer
-- PURPOSE:
--   • Reduce literal fractions: 5/4, 3/8, etc
--   • Match only adjacent tokens: NUMBER "/" NUMBER
--   • Destructive pass (token replacement)
--   • NO semantic meaning beyond numeric value

local TokenMap = require("parsers.board_data.lex.token_mappings")

local ReduceFraction = {}

local function make_numeric_token(value, source_tokens)
    return {
        raw    = tostring(value),
        lex    = TokenMap.LEX.NUMBER,
        meta   = {
            value  = value,
            source = source_tokens, -- original tokens for inspection/debug
        },
        traits = {
            numeric      = true,
            numeric_form = "fraction_resolved",
        },
        labels = {},
    }
end

---@param tokens table[]
---@return table[] reduced_tokens
function ReduceFraction.run(tokens)
    assert(type(tokens) == "table", "ReduceFraction.run(): tokens must be table")

    local out = {}
    local i = 1

    while i <= #tokens do
        local a = tokens[i]
        local b = tokens[i + 1]
        local c = tokens[i + 2]

        -- Pattern: NUMBER "/" NUMBER (no whitespace)
        if a and b and c
            and a.lex == TokenMap.LEX.NUMBER
            and b.lex == TokenMap.LEX.SYMBOL and b.raw == "/"
            and c.lex == TokenMap.LEX.NUMBER
        then
            local num = tonumber(a.raw)
            local den = tonumber(c.raw)

            if num and den and den ~= 0 then
                out[#out + 1] = make_numeric_token(
                    num / den,
                    { a, b, c }
                )
                i = i + 3
                goto continue
            end
        end

        -- default passthrough
        out[#out + 1] = tokens[i]
        i = i + 1

        ::continue::
    end

    return out
end

return ReduceFraction
