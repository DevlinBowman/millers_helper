-- core/formula/math/round.lua
--
-- Formula Round Helper
--
-- Generic rounding helper used by formula contexts.

local Round = {}

------------------------------------------------
-- public
------------------------------------------------

---Round value to a fixed number of decimal places.
---
---@param value number
---@param decimals number|nil
---@return number
function Round.round(value, decimals)

    assert(type(value) == "number", "Round.round(): value number required")

    decimals = decimals or 0

    assert(type(decimals) == "number" and decimals >= 0,
        "Round.round(): decimals non-negative number required")

    local factor = 10 ^ decimals

    if value >= 0 then
        return math.floor(value * factor + 0.5) / factor
    end

    return math.ceil(value * factor - 0.5) / factor
end

return Round
