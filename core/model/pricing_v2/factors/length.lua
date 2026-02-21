-- core/model/pricing_v2/factors/length.lua
--
-- Length premium factor.
--
-- Applies ONLY when:
--   • grade grain_rank > threshold (e.g. CH)
--   • length > baseline_length_ft
--
-- Pure economic shaping. No geometry math here.

local GradeEnum = require("core.enums.grades_2")

local LengthFactor = {}
LengthFactor.id = "length"

LengthFactor.config = {

  min_length_ft = 1.0,
  baseline_length_ft = 8.0,
  max_length_ft = 20.0,

  ----------------------------------------------------------------
  -- Grade gating
  ----------------------------------------------------------------
  min_grain_rank = 3,  -- CH == CONSTRUCTION (rank 2). Apply only above this.

  ----------------------------------------------------------------
  -- Premium shaping
  ----------------------------------------------------------------
  max_bump_at_max = 0.15,   -- +12% at 20ft
  power = 1.1,

  min_multiplier = 1.0,
  max_multiplier = 1.05,
}

local function clamp(value, min_value, max_value)
  if value < min_value then return min_value end
  if value > max_value then return max_value end
  return value
end

local function above_norm(value, baseline, max_v)
  if value <= baseline then return 0.0 end
  local denom = max_v - baseline
  if denom <= 0 then return 0.0 end
  return clamp((value - baseline) / denom, 0.0, 1.0)
end

function LengthFactor.evaluate(length_ft, grade_input)

  local raw_length = tonumber(length_ft)
  if not raw_length or raw_length <= 0 then
    return { ok = false, multiplier_total = 1.0 }
  end

  local cfg = LengthFactor.config

  local grade = GradeEnum.get(grade_input)
  if not grade then
    return {
      ok = false,
      reason = "grade_not_found",
      multiplier_total = 1.0,
    }
  end

  ----------------------------------------------------------------
  -- Gate by grade
  ----------------------------------------------------------------

  if grade.grain_rank <= cfg.min_grain_rank then
    return {
      ok = true,
      gated = true,
      multiplier_total = 1.0,
    }
  end

  ----------------------------------------------------------------
  -- Normalize length
  ----------------------------------------------------------------

  local length = clamp(
    raw_length,
    cfg.min_length_ft,
    cfg.max_length_ft
  )

  local an = above_norm(
    length,
    cfg.baseline_length_ft,
    cfg.max_length_ft
  )

  if an <= 0 then
    return {
      ok = true,
      gated = false,
      multiplier_total = 1.0,
    }
  end

  ----------------------------------------------------------------
  -- Apply shaping
  ----------------------------------------------------------------

  local shaped = an ^ (cfg.power or 1.0)

  local multiplier =
    1.0 + ((cfg.max_bump_at_max or 0.0) * shaped)

  multiplier = clamp(
    multiplier,
    cfg.min_multiplier,
    cfg.max_multiplier
  )

  return {
    ok = true,

    length_ft = raw_length,
    effective_length_ft = length,

    above_norm = an,

    grade = grade.tag,
    grain_rank = grade.grain_rank,

    multiplier_total = multiplier,
  }
end

return LengthFactor
