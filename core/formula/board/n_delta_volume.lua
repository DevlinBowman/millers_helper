-- core/formula/nominal_delta.lua
--
-- Compare nominal retail dimensions against full (phenomenal) dimensions.
--
-- Baseline = FULL / phenomenal size
-- Negative delta = nominal contains less wood than full
-- Positive delta = nominal contains more wood than full (rare)

local Volume     = require("core.formula.board.volume")
local NominalMap = require("core.formula.board.nominal_map")

local NominalDelta = {}

-- Inputs:
--   base_h, base_w  -> nominal dimension keys (e.g. 2x4)
--   full_h, full_w  -> phenomenal / full dimensions
--   length_ft
--
-- Returns:
--   delta_ratio (dimensionless)
--   delta_percent

function NominalDelta.run(base_h, base_w, full_h, full_w, length_ft)
    assert(base_h and base_w and full_h and full_w and length_ft, "invalid inputs")

    -- Nominal (retail dressed)
    local nominal_h, nominal_w =
        NominalMap.resolve_pair(base_h, base_w)

    local nominal_bf = Volume.bf(nominal_h, nominal_w, length_ft)
    local full_bf    = Volume.bf(full_h, full_w, length_ft)

    if full_bf <= 0 then
        return 0, 0
    end

    local delta_ratio = (nominal_bf - full_bf) / full_bf

    return delta_ratio, delta_ratio * 100
end

return NominalDelta
