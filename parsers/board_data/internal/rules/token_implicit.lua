-- parsers/board_data/internal/rules/token_implicit.lua
--
-- Token-scoped implicit rules
-- PURPOSE:
--   • Provide fallback inference when explicit structure is missing
--   • Lower confidence by design

local P = require("parsers.board_data.internal.pattern.predicates")

local Rules = {}

-- Loose dimension chain allowing whitespace drift
Rules[#Rules + 1] = {
    name      = "dimension_chain_loose",
    scope     = "token",
    slot      = "dimensions",
    certainty = 0.75,
    explicit  = false,
    pattern   = {
        P.num(),
        P.hard_infix(),
        P.any(P.ws(), P.num()),
        P.num(),
        P.any(P.ws(), P.hard_infix()),
        P.num(),
    },
    evaluate  = function(m)
        local nums = {}
        for _, t in ipairs(m) do
            if t.traits and t.traits.numeric then
                nums[#nums + 1] = tonumber(t.raw)
            end
        end
        if #nums ~= 3 then return nil end
        return {
            value = {
                height = nums[1],
                width  = nums[2],
                length = nums[3],
            }
        }
    end,
}

-- First token numeric, standalone: possible count
Rules[#Rules + 1] = {
    name      = "leading_standalone_count_token",
    scope     = "token",
    slot      = "count",
    certainty = 0.70,
    explicit  = false,
    pattern   = {
        function(t, i)
            return i == 1 and t.chunk_size == 1 and t.traits and t.traits.numeric
        end
    },
    evaluate = function(m)
        return { value = tonumber(m[1].raw) }
    end,
}

-- Last token numeric, standalone: possible count
Rules[#Rules + 1] = {
    name      = "trailing_standalone_count_token",
    scope     = "token",
    slot      = "count",
    certainty = 0.70,
    explicit  = false,
    pattern   = {
        function(t, i, tokens)
            return i == #tokens and t.chunk_size == 1 and t.traits and t.traits.numeric
        end
    },
    evaluate = function(m)
        return { value = tonumber(m[1].raw) }
    end,
}

return Rules
