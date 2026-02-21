-- core/model/pricing_v2/factors/grade.lua
--
-- Grade pricing factor.
-- Pulls multiplier from grade enum and applies optional nonlinear scaling.

local GradeEnum = require("core.enums.grades_2")

local GradeFactor = {}
GradeFactor.id = "grade"

GradeFactor.config = {

  enabled = true,

  ----------------------------------------------------------------
  -- Optional nonlinear amplification by rank
  ----------------------------------------------------------------
  nonlinear = {
    enabled = false,

    -- Only apply above this grain rank
    min_grain_rank = 3,   -- e.g. SELECT and above

    -- How aggressively to amplify high grades
    rank_power = 1.015,


    -- Safety caps
    min_multiplier = 0.50,
    max_multiplier = 5.00,
  },
}

local function clamp(value, min_value, max_value)
  if value < min_value then return min_value end
  if value > max_value then return max_value end
  return value
end

function GradeFactor.evaluate(grade_input)

  if not GradeFactor.config.enabled then
    return {
      ok = true,
      multiplier_total = 1.0,
      grade = nil,
    }
  end

  local grade = GradeEnum.get(grade_input)

  if not grade then
    return {
      ok = false,
      reason = "grade_not_found",
      multiplier_total = 1.0,
    }
  end

  local base_multiplier = grade.multiplier or 1.0
  local final_multiplier = base_multiplier

  ----------------------------------------------------------------
  -- Optional nonlinear scaling
  ----------------------------------------------------------------

  local nl = GradeFactor.config.nonlinear

  if nl.enabled and grade.grain_rank >= (nl.min_grain_rank or 1) then
    local shaped =
      base_multiplier ^ (nl.rank_power or 1.0)

    final_multiplier = clamp(
      shaped,
      nl.min_multiplier or 0.0,
      nl.max_multiplier or math.huge
    )
  end

  return {
    ok = true,

    grade = grade.tag,
    zone = grade.zone,
    grain = grade.grain,

    zone_rank = grade.zone_rank,
    grain_rank = grade.grain_rank,
    combined_rank = grade.rank,

    base_multiplier = base_multiplier,
    multiplier_total = final_multiplier,
  }
end

return GradeFactor
