-- parsers/board_data/token_mappings.lua
--
-- Authoritative token vocabulary + primitive patterns
-- PURPOSE:
--   • Define WHAT tokens are allowed to exist
--   • Define HOW they may appear lexically
--   • Feed tokenizer + validators
--   • NO inference, NO board logic
--
-- Any new token shape MUST be added here first.

local TokenMap = {}

----------------------------------------------------------------
-- Token kinds (closed set)
----------------------------------------------------------------
TokenMap.KINDS = {
    NUMBER = "number",
    WORD   = "word",
    UNIT   = "unit",
    SEP    = "sep",
    TAG    = "tag",
    OP     = "op",
    WS     = "ws"
}

----------------------------------------------------------------
-- Operators (structural only)
----------------------------------------------------------------
TokenMap.OPERATORS = {
    ASSIGN = {
        "::",
        "=",
        ":",
    },

    LIST = {
        ",",
    },

    CLAUSE = {
        ";",
    },
}

----------------------------------------------------------------
-- Separators (dimension / multiplicative glue)
----------------------------------------------------------------
TokenMap.SEPARATORS = {
    "x",
    "X",
    "*",
    "@",
    "by",
}

----------------------------------------------------------------
-- Numeric forms (allowed shapes)
----------------------------------------------------------------
TokenMap.NUMERIC = {
    patterns = {
        integer  = "^%d+$",          -- 2, 12
        decimal  = "^%d*%.%d+$",     -- .75, 1.5
        fraction = "^%d+/%d+$",      -- 3/4
    },

    words = {
        zero = 0,
        one = 1,
        two = 2,
        three = 3,
        four = 4,
        five = 5,
        six = 6,
        seven = 7,
        eight = 8,
        nine = 9,
        ten = 10,
        eleven = 11,
        twelve = 12,
        thirteen = 13,
        fourteen = 14,
        fifteen = 15,
        sixteen = 16,
        seventeen = 17,
        eighteen = 18,
        nineteen = 19,
        twenty = 20,
    },
}

----------------------------------------------------------------
-- Units (dimension-agnostic)
----------------------------------------------------------------
TokenMap.UNITS = {
    length = {
        "in", "inch", "inches", "\"",
        "ft", "foot", "feet", "'",
        "lf", "lft", "ln", "linear",
    },

    count = {
        "pc", "pcs", "piece", "pieces",
        "ea", "each",
        "ct", "count",
        "qty", "quantity",
    },
}

----------------------------------------------------------------
-- Tags (normalized output only)
----------------------------------------------------------------
TokenMap.TAGS = {
    n = { "n", "nom", "nominal" },
    f = { "f", "full", "actual", "true" },
}

----------------------------------------------------------------
-- Word patterns (classification hints only)
----------------------------------------------------------------
TokenMap.WORD_PATTERNS = {
    alpha      = "^[A-Za-z]+$",
    alnum      = "^[A-Za-z0-9]+$",
    grade_code = "^[A-Z]{2}$",       -- CC, RW
    surface    = "^[A-Z][A-Z0-9]+$", -- S4S, KD
}

----------------------------------------------------------------
-- Precompiled lookup tables (for tokenizer speed)
----------------------------------------------------------------
local function invert(list)
    local out = {}
    for _, v in ipairs(list) do
        out[string.lower(v)] = true
    end
    return out
end

TokenMap._LOOKUP = {
    separators = invert(TokenMap.SEPARATORS),
    operators  = {},
    units      = {},
    tags       = {},
}

for _, group in pairs(TokenMap.OPERATORS) do
    for _, op in ipairs(group) do
        TokenMap._LOOKUP.operators[op] = true
    end
end

for _, group in pairs(TokenMap.UNITS) do
    for _, u in ipairs(group) do
        TokenMap._LOOKUP.units[string.lower(u)] = true
    end
end

for canon, variants in pairs(TokenMap.TAGS) do
    for _, v in ipairs(variants) do
        TokenMap._LOOKUP.tags[string.lower(v)] = canon
    end
end

----------------------------------------------------------------
-- Public helpers (used by tokenizer, NOT parser)
----------------------------------------------------------------

function TokenMap.is_separator(s)
    return TokenMap._LOOKUP.separators[string.lower(s)] == true
end

function TokenMap.is_operator(s)
    return TokenMap._LOOKUP.operators[s] == true
end

function TokenMap.is_unit(s)
    return TokenMap._LOOKUP.units[string.lower(s)] == true
end

function TokenMap.is_tag(s)
    return TokenMap._LOOKUP.tags[string.lower(s)] ~= nil
end

function TokenMap.normalize_tag(s)
    return TokenMap._LOOKUP.tags[string.lower(s)]
end

return TokenMap
