-- core/model/pricing_v2/factors/waste_faces.lua
--
-- Deterministic faces waste adjustment driven by kerf model.
-- Adjustment is one-to-one with waste_ratio, relative to a baseline face (2x6).
--
-- multiplier = waste_ratio(face) / waste_ratio(baseline_face)
--
-- Notes:
--   waste_ratio is independent of length, but Kerf.run needs l, so we pass 1ft.

local Kerf = require("core.formula.board.kerf")

local WasteFacesFactor = {}

WasteFacesFactor.id = "waste_faces"

WasteFacesFactor.config = {
  baseline_face = { h = 2.0, w = 6.0 }, -- 2x6 baseline
  default_kerf_in = 0.3125,             -- 5/16
}

local function safe_number(value, fallback)
  local n = tonumber(value)
  if n == nil then return fallback end
  return n
end

local function clamp_min(value, min_value)
  if value < min_value then return min_value end
  return value
end

local function waste_ratio_for_face(h, w, kerf_in)
  local r = Kerf.run({ h = h, w = w, l = 1.0 }, kerf_in) -- length irrelevant for ratio
  local ratio = safe_number(r.waste_ratio, 0.0)
  return clamp_min(ratio, 0.0)
end

function WasteFacesFactor.evaluate(face, opts)
  local o = opts or {}

  local h = safe_number((face or {}).h or (face or {}).height_in, nil)
  local w = safe_number((face or {}).w or (face or {}).width_in, nil)

  local kerf_in = safe_number(o.kerf_in, WasteFacesFactor.config.default_kerf_in)
  if kerf_in < 0 then kerf_in = 0 end

  if not h or not w or h <= 0 or w <= 0 then
    return {
      ok = false,
      reason = "missing_or_invalid_face_dimensions",
      kerf_in = kerf_in,
      baseline_ratio = 0.0,
      waste_ratio = 0.0,
      relative_ratio = 1.0,
      multiplier = 1.0,
    }
  end

  local base = WasteFacesFactor.config.baseline_face
  local baseline_ratio = waste_ratio_for_face(base.h, base.w, kerf_in)
  local waste_ratio = waste_ratio_for_face(h, w, kerf_in)

  local relative_ratio = 1.0
  if baseline_ratio > 0 then
    relative_ratio = waste_ratio / baseline_ratio
  end

  ----------------------------------------------------------------
  -- ECONOMIC DAMPENING
  ----------------------------------------------------------------

  -- Controls how strongly waste influences price (0.05–0.15 recommended)
  local intensity = 0.10

  local multiplier =
    1.0 + intensity * (relative_ratio - 1.0)

  return {
    ok = true,
    kerf_in = kerf_in,
    baseline_ratio = baseline_ratio,
    waste_ratio = waste_ratio,
    relative_ratio = relative_ratio,
    multiplier = multiplier,
  }
end

return WasteFacesFactor
