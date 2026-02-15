-- parsers/board_data/internal/lex/reduce_fractional_number.lua

local TokenMap = require("parsers.board_data.internal.lex.token_mappings")

local ReduceFraction = {}

local function make_numeric_token(value, source_tokens)
    local first = source_tokens[1]
    local raw   = tostring(value)

    return {
        -- preserve original stream position
        index  = first.index,

        raw    = raw,
        lex    = TokenMap.LEX.NUMBER,

        meta   = {
            value  = value,
            len    = #raw,
            source = source_tokens,
        },

        traits = {
            numeric      = true,
            numeric_form = "fraction_resolved",
        },

        labels = {},
    }
end

function ReduceFraction.run(tokens)
    assert(type(tokens) == "table", "ReduceFraction.run(): tokens must be table")

    local out = {}
    local i   = 1

    while i <= #tokens do
        local a = tokens[i]
        local b = tokens[i + 1]
        local c = tokens[i + 2]

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

        out[#out + 1] = tokens[i]
        i = i + 1

        ::continue::
    end

    return out
end

return ReduceFraction
