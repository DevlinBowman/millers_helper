local Faces      = require("core.model.pricing_v2.factors.faces")
local NominalMap = require("core.formula.board.nominal_map")
local Graph      = require("core.model.pricing_v2.tools.ascii_graph")

local function safe(v) return tonumber(v) or 0 end

local function nominal_actual_values()
  local values = {}
  for _, actual in pairs(NominalMap.FACE or {}) do
    values[#values + 1] = actual
  end
  table.sort(values)
  return values
end

local function nominal_full_values()
  local values = {}
  for nominal, _ in pairs(NominalMap.FACE or {}) do
    values[#values + 1] = nominal
  end
  table.sort(values)
  return values
end

local function combined(result)
  return (((result or {}).components or {}).combined or {})
end

local function print_face_row(h, w, kerf_in)
  local r = Faces.evaluate({ width_in = w, height_in = h }, { kerf_in = kerf_in })
  local c = combined(r)

  local total      = safe(r.multiplier_total)
  local time_m     = safe((c.production_time or {}).multiplier)
  local scarcity_m = safe((c.scarcity or {}).multiplier)
  local waste_m    = safe((c.waste or {}).multiplier)

  local waste_ratio = safe((c.waste or {}).waste_ratio)
  local base_ratio  = safe((c.waste or {}).baseline_ratio)

  print(string.format(
    "h=%6.2f  w=%6.2f  total=%7.4f  | time=%6.4f scarcity=%6.4f waste=%6.4f | waste_ratio=%7.5f base=%7.5f",
    h, w,
    total,
    time_m, scarcity_m, waste_m,
    waste_ratio, base_ratio
  ))
end

local function print_nominal_matrix(kerf_in)
  print("\n=== NOMINAL ACTUAL FACE MATRIX ===\n")

  local actuals = nominal_actual_values()

  for _, h in ipairs(actuals) do
    for _, w in ipairs(actuals) do
      print_face_row(h, w, kerf_in)
    end
  end
end

local function print_full_dimension_matrix(kerf_in)
  print("\n=== FULL DIMENSION FACE MATRIX ===\n")

  local fulls = nominal_full_values()

  for _, h in ipairs(fulls) do
    for _, w in ipairs(fulls) do
      print_face_row(h, w, kerf_in)
    end
  end
end

local function graph_surface_slices(kerf_in)
  local actuals = nominal_actual_values()

  for _, fixed_height in ipairs(actuals) do
    Graph.print_factor({
      title = string.format(
        "Faces slice (h=%.2f, kerf=%.4f)",
        fixed_height, kerf_in
      ),
      x_min = 2,
      x_max = 12,
      x_step = 0.05,
      columns = 72,
      rows = 18,
      x_label_places = 2,
      y_label_places = 3,

      markers = actuals,

      eval = function(x)
        local r = Faces.evaluate(
          { width_in = x, height_in = fixed_height },
          { kerf_in = kerf_in }
        )
        return safe(r.multiplier_total)
      end
    })
  end
end

local function run()
  local kerf_in = 0.3125

  print_nominal_matrix(kerf_in)
  print_full_dimension_matrix(kerf_in)

  graph_surface_slices(kerf_in)
end

run()
