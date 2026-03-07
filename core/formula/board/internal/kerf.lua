-- core/formula/board/internal/kerf.lua
--
-- Board Kerf Formula
--
-- Pure kerf waste model expressed in board-foot terms.

local Volume = require("core.formula.board.internal.volume")

local Kerf = {}

------------------------------------------------
-- internal helpers
------------------------------------------------

local function waste_ratio(h, w, kerf)
    local numerator = kerf * (h + w) - (kerf * kerf)
    local denominator = h * w
    return numerator / denominator
end

------------------------------------------------
-- public
------------------------------------------------

---Return kerf waste model for one board.
---
---@param h number
---@param w number
---@param l number
---@param kerf number
---@return FormulaKerfResult
function Kerf.run(h, w, l, kerf)

    assert(type(h) == "number", "Kerf.run(): h number required")
    assert(type(w) == "number", "Kerf.run(): w number required")
    assert(type(l) == "number", "Kerf.run(): l number required")
    assert(type(kerf) == "number" and kerf >= 0, "Kerf.run(): kerf non-negative number required")

    local ratio = waste_ratio(h, w, kerf)
    local total_bf = Volume.bf(h, w, l)

    return {
        waste_ratio = ratio,
        waste_total_bf = ratio * total_bf,
    }
end

return Kerf
