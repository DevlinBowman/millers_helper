-- pricing/tools/debug/test_faces_heatmap.lua
--
-- 2D ANSI heatmap of Faces.multiplier_total over (height × width).
--
-- Upgrades:
--   • Fixed encoding/garbage glyph issues (pure ASCII source)
--   • Fixed axis alignment (1 char per cell)
--   • Masks outside mill-allowable region (height cap, width cap)
--   • Diverging color map centered on baseline multiplier_total = 1.0
--       - blue  : < 1.0  (discount)
--       - gray  : ≈ 1.0  (baseline)
--       - red   : > 1.0  (premium)
--   • Clear legend: values are multiplier_total
--   • Optional overlay markers for nominal actual faces
--
-- Usage:
--   lua pricing/tools/debug/test_faces_heatmap.lua
--
-- NOTE:
--   Requires a terminal that supports ANSI 256 colors.

local Faces      = require("core.model.pricing_v2.factors.faces")
local NominalMap = require("core.formula.board.nominal_map")

local function safe(v) return tonumber(v) or 0 end

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local CONFIG = {
  width_min  = 2.0,
  width_max  = 12.0,

  height_min = 0.75,
  height_max = 8.0,     -- mill cap: 8" max height (adjust if needed)

  baseline_width = 6.0,

  rows = 24,            -- vertical resolution
  cols = 84,            -- horizontal resolution

  kerf_in = 0.3125,     -- 5/16

  -- 1 char per cell for perfect alignment
  cell_char = "#",      -- try "#", "█" (if your file encoding is UTF-8), or "*"

  -- If true, clamp height_max to largest nominal actual <= mill cap
  clamp_height_to_nominal = true,

  -- Overlay nominal actual positions with a marker (no color)
  overlay_nominal_marks = true,
  overlay_char = "o",
}

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function nominal_actual_values()
  local values = {}
  for _, actual in pairs(NominalMap.FACE or {}) do
    values[#values + 1] = actual
  end
  table.sort(values)
  return values
end

local function compute_height_max(cfg)
  if not cfg.clamp_height_to_nominal then
    return cfg.height_max
  end

  local max_h = cfg.height_max
  local actuals = nominal_actual_values()

  local best = cfg.height_min
  for _, a in ipairs(actuals) do
    if a <= max_h and a > best then
      best = a
    end
  end
  return best
end

local function is_allowed(cfg, w, h, effective_height_max)
  if w < cfg.width_min or w > cfg.width_max then return false end
  if h < cfg.height_min or h > effective_height_max then return false end
  return true
end

----------------------------------------------------------------
-- DIVERGING ANSI COLOR MAP (centered at baseline=1.0)
----------------------------------------------------------------

local function ansi_fg_256(idx)
  return "\27[38;5;" .. tostring(idx) .. "m"
end

local function ansi_reset()
  return "\27[0m"
end

-- Discrete ramps (monotonic) to avoid 256-color weirdness.
local BLUE_RAMP = { 27, 33, 39, 45, 51 }      -- discount side
local RED_RAMP  = { 208, 202, 196 }           -- premium side
local NEUTRAL   = 250                         -- baseline (gray)

local function fg_color_for_value(v, vmin, vmax)
  local baseline = 1.0

  local max_dev = math.max(
    math.abs(vmin - baseline),
    math.abs(vmax - baseline)
  )

  if max_dev < 1e-9 then
    return ansi_fg_256(NEUTRAL)
  end

  local t = (v - baseline) / max_dev
  t = clamp(t, -1.0, 1.0)

  -- near baseline
  if math.abs(t) < 0.05 then
    return ansi_fg_256(NEUTRAL)
  end

  if t < 0 then
    local intensity = math.abs(t)
    local idx = 1 + math.floor(intensity * (#BLUE_RAMP - 1) + 0.5)
    return ansi_fg_256(BLUE_RAMP[idx])
  end

  local idx = 1 + math.floor(t * (#RED_RAMP - 1) + 0.5)
  return ansi_fg_256(RED_RAMP[idx])
end

----------------------------------------------------------------
-- GRID SAMPLING
----------------------------------------------------------------

local function build_surface_grid(cfg)
  local grid = {}
  local vmin = math.huge
  local vmax = -math.huge

  local effective_height_max = compute_height_max(cfg)

  for r = 1, cfg.rows do
    local h = cfg.height_min
      + (r - 1) / (cfg.rows - 1)
      * (effective_height_max - cfg.height_min)

    grid[r] = {}

    for c = 1, cfg.cols do
      local w = cfg.width_min
        + (c - 1) / (cfg.cols - 1)
        * (cfg.width_max - cfg.width_min)

      if is_allowed(cfg, w, h, effective_height_max) then
        local result = Faces.evaluate(
          { width_in = w, height_in = h },
          { kerf_in = cfg.kerf_in }
        )

        local v = safe(result.multiplier_total)
        grid[r][c] = v

        if v < vmin then vmin = v end
        if v > vmax then vmax = v end
      else
        grid[r][c] = nil
      end
    end
  end

  if vmin == math.huge or vmax == -math.huge then
    vmin, vmax = 0.0, 1.0
  end

  return grid, vmin, vmax, effective_height_max
end

----------------------------------------------------------------
-- AXIS MAPPING
----------------------------------------------------------------

local function col_for_width(cfg, w)
  local t = (w - cfg.width_min) / (cfg.width_max - cfg.width_min)
  t = clamp(t, 0.0, 1.0)
  return 1 + math.floor(t * (cfg.cols - 1) + 0.5)
end

local function row_for_height(cfg, h, effective_height_max)
  local t = (h - cfg.height_min) / (effective_height_max - cfg.height_min)
  t = clamp(t, 0.0, 1.0)
  return 1 + math.floor(t * (cfg.rows - 1) + 0.5)
end

local function build_nominal_overlay(cfg, effective_height_max)
  local overlay = {}
  for r = 1, cfg.rows do overlay[r] = {} end

  if not cfg.overlay_nominal_marks then
    return overlay
  end

  local actuals = nominal_actual_values()
  for _, h in ipairs(actuals) do
    for _, w in ipairs(actuals) do
      if h <= effective_height_max and w >= cfg.width_min and w <= cfg.width_max then
        local r = row_for_height(cfg, h, effective_height_max)
        local c = col_for_width(cfg, w)
        overlay[r][c] = true
      end
    end
  end

  return overlay
end

----------------------------------------------------------------
-- PRINT
----------------------------------------------------------------

local function print_heatmap(cfg, grid, vmin, vmax, effective_height_max)
  local overlay = build_nominal_overlay(cfg, effective_height_max)

  print("\n=== FACES FACTOR SURFACE ===\n")
  print("Mapping: multiplier_total (faces factor)")
  print(string.format("Range: %.4f -> %.4f", vmin, vmax))
  print(string.format(
    "Domain: width %.2f..%.2f, height %.2f..%.2f (kerf=%.4f)",
    cfg.width_min, cfg.width_max,
    cfg.height_min, effective_height_max,
    cfg.kerf_in
  ))
  print("")

  -- Heatmap body: print highest height at top
  for r = cfg.rows, 1, -1 do
    local h = cfg.height_min
      + (r - 1) / (cfg.rows - 1)
      * (effective_height_max - cfg.height_min)

    io.write(string.format("%6.2f | ", h))

    for c = 1, cfg.cols do
      local v = grid[r][c]
      if v == nil then
        io.write(" ")
      else
        if overlay[r] and overlay[r][c] then
          io.write(ansi_fg_256(15) .. cfg.overlay_char .. ansi_reset()) -- white marker
        else
          io.write(fg_color_for_value(v, vmin, vmax) .. cfg.cell_char .. ansi_reset())
        end
      end
    end

    io.write("\n")
  end

  -- X axis line
  io.write("       +")
  io.write(string.rep("-", cfg.cols))
  io.write("\n")

  -- Width labels
  local label_line = {}
  for i = 1, cfg.cols do label_line[i] = " " end

  local function write_label(value)
    local col = col_for_width(cfg, value)
    local txt = string.format("%.0f", value)
    local start = col - math.floor(#txt / 2)
    for i = 1, #txt do
      local idx = start + i - 1
      if idx >= 1 and idx <= cfg.cols then
        label_line[idx] = txt:sub(i, i)
      end
    end
  end

  write_label(cfg.width_min)
  write_label(cfg.baseline_width)
  write_label(cfg.width_max)

  print("        " .. table.concat(label_line))
  print("")

  -- Legend (diverging, baseline-centered)
  print("Legend: color encodes multiplier_total relative to baseline=1.00")
  print("  blue  : < 1.00 (discount)")
  print("  gray  : ~= 1.00 (baseline)")
  print("  red   : > 1.00 (premium)")
  print("")

  local samples = { vmin, 0.75, 1.00, 1.25, vmax }
  io.write("  ")
  for _, v in ipairs(samples) do
    io.write(fg_color_for_value(v, vmin, vmax) .. cfg.cell_char .. ansi_reset())
    io.write(string.format(" %.2f  ", v))
  end
  print("\n")

  if cfg.overlay_nominal_marks then
    print("Overlay: 'o' marks nominal-actual face intersections (NominalMap.FACE × NominalMap.FACE)\n")
  end
end

----------------------------------------------------------------
-- RUN
----------------------------------------------------------------

local function run()
  local cfg = CONFIG
  local grid, vmin, vmax, effective_height_max = build_surface_grid(cfg)
  print_heatmap(cfg, grid, vmin, vmax, effective_height_max)
end

run()
