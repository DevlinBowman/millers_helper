-- core/formula/math/api/surface.lua
--
-- Formula Math API
--
-- Generic math helpers shared across formula domains.

local Round = require("core.formula.math.internal.round")

---@class FormulaMathAPI
local Math = {}

------------------------------------------------
-- round
------------------------------------------------

---Round value to fixed decimal places.
---
---Example
---  Math.round(3.14159, 2)
---
---@param value number
---@param decimals number|nil
---@return number
function Math.round(value, decimals)
    return Round.round(value, decimals)
end

return Math
