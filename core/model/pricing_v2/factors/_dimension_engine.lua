-- core/model/pricing_v2/factors/_dimension_engine.lua

local Engine = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function clamp(value, min_value, max_value)
  if value < min_value then return min_value end
  if value > max_value then return max_value end
  return value
end

local function below_norm(value, min_v, baseline_v)
  if value >= baseline_v then return 0.0 end
  local denom = baseline_v - min_v
  if denom <= 0 then return 0.0 end
  return clamp((baseline_v - value) / denom, 0.0, 1.0)
end

local function above_norm(value, baseline_v, max_v)
  if value <= baseline_v then return 0.0 end
  local denom = max_v - baseline_v
  if denom <= 0 then return 0.0 end
  return clamp((value - baseline_v) / denom, 0.0, 1.0)
end

local function apply_component(cfg, bn, an, min_mult, max_mult)
  local m = 1.0

  if bn > 0 then
    local shaped = bn ^ (cfg.below_power or 1.0)
    m = m
      + ((cfg.below_max_bump_at_min or 0.0) * shaped)
      - ((cfg.below_max_cut_at_min  or 0.0) * shaped)
  end

  if an > 0 then
    local shaped = an ^ (cfg.above_power or 1.0)
    m = m
      + ((cfg.above_max_bump_at_max or 0.0) * shaped)
      - ((cfg.above_max_cut_at_max  or 0.0) * shaped)
  end

  return clamp(m, min_mult, max_mult)
end

local function nearest_distance(value, candidates)
  local min_dist = math.huge
  for _, v in ipairs(candidates or {}) do
    local d = math.abs(value - v)
    if d < min_dist then
      min_dist = d
    end
  end
  if min_dist == math.huge then return 0 end
  return min_dist
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function Engine.evaluate(value_in, config)
  local raw = tonumber(value_in)
  if not raw or raw <= 0 then
    return { ok = false, multiplier_total = 1.0 }
  end

  local min_v = config.min_value
  local base_v = config.baseline_value
  local max_v = config.max_value

  local value = clamp(raw, min_v, max_v)

  local bn = below_norm(value, min_v, base_v)
  local an = above_norm(value, base_v, max_v)

  local components = {}
  local total = 1.0

  ----------------------------------------------------------------
  -- Bidirectional components
  ----------------------------------------------------------------

  for name, cfg in pairs(config.components or {}) do
    local m = 1.0
    if cfg.enabled then
      m = apply_component(
        cfg,
        bn,
        an,
        config.min_component_multiplier,
        config.max_component_multiplier
      )
    end

    components[name] = {
      enabled = cfg.enabled,
      multiplier = m,
      below_norm = bn,
      above_norm = an,
    }

    total = total * m
  end

  ----------------------------------------------------------------
  -- Nominal deviation (optional)
  ----------------------------------------------------------------

  local nominal_component = nil

  if config.nominal and config.nominal.enabled then
    local nominal_values = {}

    if type(config.nominal.nominal_values) == "function" then
      nominal_values = config.nominal.nominal_values() or {}
    end

    local distance = nearest_distance(value, nominal_values)

    local nominal_multiplier = 1.0

    if distance > 1e-6 then
      local span = max_v - min_v
      local distance_norm = clamp(distance / span, 0.0, 1.0)

      local domain_norm = clamp(
        (value - min_v) / span,
        0.0,
        1.0
      )

      local shaped_distance = distance_norm ^ (config.nominal.distance_power or 1.0)
      local shaped_domain   = domain_norm ^ (config.nominal.domain_power or 1.0)

      local intensity = shaped_distance * shaped_domain

      nominal_multiplier =
        1.0 + ((config.nominal.max_bump_at_max or 0.0) * intensity)
    end

    nominal_component = {
      enabled = true,
      multiplier = nominal_multiplier,
      distance_from_nominal = distance,
    }

    total = total * nominal_multiplier
  end

  total = clamp(total,
    config.min_total_multiplier,
    config.max_total_multiplier
  )

  return {
    ok = true,
    raw = raw,
    effective = value,
    baseline = base_v,
    below_norm = bn,
    above_norm = an,
    multiplier_total = total,
    components = components,
    nominal = nominal_component,
  }
end

return Engine
