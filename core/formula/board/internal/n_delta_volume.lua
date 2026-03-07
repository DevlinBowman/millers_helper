-- core/formula/board/internal/n_delta_volume.lua
--
-- Board Nominal Delta Formula
--
-- Compare nominal-reference volume against delivered board volume.
--
-- Inputs:
--   • base_h / base_w → declared board dimensions
--   • h / w / l       → delivered board dimensions
--
-- Returns:
--   • delta_ratio
--   • delta_percent

local Volume     = require("core.formula.board.internal.volume")
local NominalMap = require("core.formula.board.internal.nominal_map")

local NominalDelta = {}

------------------------------------------------
-- public
------------------------------------------------

---Return nominal-reference volume delta.
---
---@param base_h number
---@param base_w number
---@param h number
---@param w number
---@param l number
---@return number delta_ratio
---@return number delta_percent
function NominalDelta.run(base_h, base_w, h, w, l)

    assert(type(base_h) == "number", "NominalDelta.run(): base_h number required")
    assert(type(base_w) == "number", "NominalDelta.run(): base_w number required")
    assert(type(h) == "number", "NominalDelta.run(): h number required")
    assert(type(w) == "number", "NominalDelta.run(): w number required")
    assert(type(l) == "number", "NominalDelta.run(): l number required")

    local nominal_h, nominal_w = NominalMap.resolve_pair(base_h, base_w)

    local nominal_bf = Volume.bf(nominal_h, nominal_w, l)
    local full_bf = Volume.bf(h, w, l)

    if full_bf <= 0 then
        return 0, 0
    end

    local ratio = (nominal_bf - full_bf) / full_bf

    return ratio, ratio * 100
end

return NominalDelta
