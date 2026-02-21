-- core/model/pricing_v2/factors/length.lua
--
-- Length premium factor.
--
-- Applies ONLY when:
--   • Grade economic value > CC (Construction Common)
--   • Length > baseline_length_ft (8ft default)
--
-- Pure economic shaping.
-- No geometry logic here.

local GradeEnum = require("core.enums.grades")

local LengthFactor = {}
LengthFactor.id = "length"

LengthFactor.config = {

  min_length_ft = 1.0,
  baseline_length_ft = 8.0,
  max_length_ft = 20.0,

  ----------------------------------------------------------------
  -- Grade gating reference
  ----------------------------------------------------------------
  reference_grade_tag = "CC",  -- must exceed this economically

  ----------------------------------------------------------------
  -- Premium shaping
  ----------------------------------------------------------------
  max_bump_at_max = 0.40,   -- +40% at max_length_ft
  power = 1.5,

  min_multiplier = 1.0,
  max_multiplier = 2.0,
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function LengthFactor.evaluate(length_ft, grade_input)

  local raw_length = tonumber(length_ft)
  if not raw_length or raw_length <= 0 then
    return {
      ok = false,
      reason = "invalid_length",
      multiplier_total = 1.0,
    }
  end

  local cfg = LengthFactor.config

  ----------------------------------------------------------------
  -- Resolve grade
  ----------------------------------------------------------------

  local grade = GradeEnum.get(grade_input)

  if not grade or grade.kind ~= "grade" then
    return {
      ok = false,
      reason = "grade_not_found",
      multiplier_total = 1.0,
    }
  end

  ----------------------------------------------------------------
  -- Gate by economic value relative to reference grade
  ----------------------------------------------------------------

  local reference = GradeEnum.get(cfg.reference_grade_tag)

  if not reference or not GradeEnum.higher_value(grade, reference) then
    return {
      ok = true,
      gated = true,
      multiplier_total = 1.0,
      grade = grade.tag,
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
      grade = grade.tag,
      length_ft = raw_length,
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

    grade = grade.tag,
    grade_value = grade.value,

    length_ft = raw_length,
    effective_length_ft = length,

    baseline_length_ft = cfg.baseline_length_ft,
    above_norm = an,

    multiplier_total = multiplier,
  }
end

return LengthFactor
