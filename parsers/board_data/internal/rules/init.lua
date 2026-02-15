-- parsers/board_data/rules/init.lua
--
-- Authoritative rule registry
-- PURPOSE:
--   • Provide a single ordered list of all board parsing rules
--   • Preserve deterministic evaluation order
--   • Serve as the only public import point for rules

local Rules = {}

local function append(dst, src)
    for i = 1, #src do
        dst[#dst + 1] = src[i]
    end
end

-- Ordering is intentional and significant:
--   1. Explicit token rules (highest confidence)
--   2. Explicit chunk rules
--   3. Implicit token rules (fallback)
--   4. Implicit chunk rules (contextual heuristics)

append(Rules, require("parsers.board_data.internal.rules.token_explicit"))
append(Rules, require("parsers.board_data.internal.rules.chunk_explicit"))
append(Rules, require("parsers.board_data.internal.rules.token_implicit"))
append(Rules, require("parsers.board_data.internal.rules.chunk_implicit"))

return Rules
