-- parsers/board_data/internal/rules/token_explicit.lua
--
-- Token-scoped explicit rules
-- PURPOSE:
--   • Assert meaning from unambiguous local syntax
--   • No heuristics, no positional guessing
--   • Highest confidence rules

local P = require("platform.parsers.board_data.internal.pattern.predicates")

local Rules = {}

-- Numeric value followed by a count unit: "10 pcs"
Rules[#Rules + 1] = {
    name      = "explicit_count_postfix",
    scope     = "token",
    slot      = "count",
    certainty = 0.98,
    explicit  = true,
    pattern   = { P.num(), P.unit("count") },
    evaluate  = function(m) return { value = tonumber(m[1].raw) } end,
}

-- Count unit followed by numeric value: "pcs 10"
Rules[#Rules + 1] = {
    name      = "explicit_count_prefix",
    scope     = "token",
    slot      = "count",
    certainty = 0.95,
    explicit  = true,
    pattern   = { P.unit("count"), P.num() },
    evaluate  = function(m) return { value = tonumber(m[2].raw) } end,
}

-- Numeric value followed by length unit: "8 ft"
Rules[#Rules + 1] = {
    name      = "explicit_length_postfix",
    scope     = "token",
    slot      = "length",
    certainty = 0.98,
    explicit  = true,
    pattern   = { P.num(), P.unit("length") },
    evaluate  = function(m) return { value = tonumber(m[1].raw) } end,
}

-- Length unit followed by numeric value: "ft 8"
Rules[#Rules + 1] = {
    name      = "explicit_length_prefix",
    scope     = "token",
    slot      = "length",
    certainty = 0.95,
    explicit  = true,
    pattern   = { P.unit("length"), P.num() },
    evaluate  = function(m) return { value = tonumber(m[2].raw) } end,
}

-- Strict standalone tag letter: "n" / "f"
Rules[#Rules + 1] = {
    name      = "explicit_tag_strict",
    scope     = "token",
    slot      = "tag",
    certainty = 0.98,
    explicit  = true,
    pattern   = {
        function(t) return t.traits and t.traits.tag_strict == true end
    },
    evaluate  = function(m) return { value = m[1].traits.tag_canon } end,
}

-- Exact dimension chain: "2 x 4 x 8"
Rules[#Rules + 1] = {
    name      = "explicit_dimension_chain_3",
    scope     = "token",
    slot      = "dimensions",
    certainty = 0.90,
    explicit  = true,
    pattern   = {
        P.num(), P.hard_infix(),
        P.num(), P.hard_infix(),
        P.num(),
    },
    evaluate  = function(m)
        return {
            value = {
                height = tonumber(m[1].raw),
                width  = tonumber(m[3].raw),
                length = tonumber(m[5].raw),
            }
        }
    end,
}

-- Dimension chain with trailing tag: "2x4x8f"
Rules[#Rules + 1] = {
    name      = "explicit_dimension_chain_with_tag",
    scope     = "token",
    slot      = "dimensions",
    certainty = 0.95,
    explicit  = true,
    pattern   = {
        P.num(), P.hard_infix(),
        P.num(), P.hard_infix(),
        P.num(), P.tag(),
    },
    evaluate  = function(m)
        return {
            value = {
                height = tonumber(m[1].raw),
                width  = tonumber(m[3].raw),
                length = tonumber(m[5].raw),
                tag    = m[6].traits.tag_canon,
            }
        }
    end,
}

return Rules
