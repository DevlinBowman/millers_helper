-- parsers/board_data/lex/token_mappings.lua
--
-- Authoritative token vocabulary + primitive patterns
-- PURPOSE:
--   • Define vocabulary and primitive shapes
--   • Provide context-free lookup helpers
--   • NO inference, NO parsing, NO reduction

local TokenMap = {}

----------------------------------------------------------------
-- Lexical kinds (for lexer output only)
----------------------------------------------------------------
TokenMap.LEX = {
    NUMBER = "number",
    WORD   = "word",
    OP     = "op",
    WS     = "ws",
    SYMBOL = "symbol",
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
-- Separators (candidate tokens; meaning is contextual)
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
-- Units (dimension-agnostic; meaning is contextual)
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
-- NOTE: "n"/"f" single-letter are treated as strict tags
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
-- Precompiled lookup tables (for speed)
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
    units_kind = {}, -- maps unit -> "length" | "count"
    tags       = {}, -- maps variant -> canon ("n"|"f")
}

for _, group in pairs(TokenMap.OPERATORS) do
    for _, op in ipairs(group) do
        TokenMap._LOOKUP.operators[op] = true
    end
end

for kind, group in pairs(TokenMap.UNITS) do
    for _, u in ipairs(group) do
        TokenMap._LOOKUP.units_kind[string.lower(u)] = kind
    end
end

for canon, variants in pairs(TokenMap.TAGS) do
    for _, v in ipairs(variants) do
        TokenMap._LOOKUP.tags[string.lower(v)] = canon
    end
end

----------------------------------------------------------------
-- Public helpers (context-free)
----------------------------------------------------------------

---@param s string
---@return boolean
function TokenMap.is_operator(s)
    return TokenMap._LOOKUP.operators[s] == true
end

---@param s string
---@return boolean
function TokenMap.is_separator_candidate(s)
    return TokenMap._LOOKUP.separators[string.lower(s)] == true
end

---@param s string
---@return boolean
function TokenMap.is_unit_candidate(s)
    return TokenMap._LOOKUP.units_kind[string.lower(s)] ~= nil
end

---@param s string
---@return ("length"|"count"|nil)
function TokenMap.unit_kind(s)
    return TokenMap._LOOKUP.units_kind[string.lower(s)]
end

---@param s string
---@return (string|nil) canon_tag  -- "n"|"f"
function TokenMap.normalize_tag(s)
    return TokenMap._LOOKUP.tags[string.lower(s)]
end

---@param s string
---@return boolean
function TokenMap.is_strict_tag_letter(s)
    local lower = string.lower(s)
    return lower == "n" or lower == "f"
end

return TokenMap
