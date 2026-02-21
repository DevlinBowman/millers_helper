-- tools/pricing_surface_dump_exact.lua
--
-- Exact structured dump of current dual-regime printer
-- Outputs CSV files (UNCHANGED)
-- Adds runtime diagnostics for minimum multiplier source

local OUTPUT_DIR = os.getenv("HOME") .. "/Desktop/board_data/in_data/"
os.execute("mkdir -p " .. OUTPUT_DIR)

local GradeEnum   = require("core.enums.grades")
local BoardPricer = require("core.model/pricing_v2/board_pricer")

local pricer = BoardPricer.new({
  baseline_price_per_bf = 2.00,
})

----------------------------------------------------------------
-- Dimension Regimes (MUST MATCH PRINTER)
----------------------------------------------------------------

local ACTUAL_HEIGHTS = { 1, 2, 4, 6, 8 }
local ACTUAL_WIDTHS  = { 1, 2, 4, 6, 8, 10, 12 }

local NOMINAL_HEIGHTS = { 0.75, 1.5, 3.5, 5.5, 7.25 }
local NOMINAL_WIDTHS  = { 0.75, 1.5, 3.5, 5.5, 7.25, 9.25, 11.25 }

local LENGTHS = { 6, 8, 10, 12, 16 }

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function sorted_grades_by_quality()
  local copy = {}
  for _, g in ipairs(GradeEnum.grades) do
    copy[#copy + 1] = g
  end

  table.sort(copy, function(a, b)
    if a.value ~= b.value then
      return a.value > b.value
    end
    return a.rank > b.rank
  end)

  return copy
end

----------------------------------------------------------------
-- Surface Generator (diagnostic enabled)
----------------------------------------------------------------

local function generate_exact_surface(heights, widths, grade)
  local rows = {}
  local matrix = {}

  -- Track minimum multiplier for this regime + grade
  local min_probe = {
    total = math.huge,
    board = nil,
    result = nil,
  }

  for _, h in ipairs(heights) do
    for _, w in ipairs(widths) do

      if h <= 8 and w <= 12 and h <= w then

        local row_label = string.format("%.2fx%.2f", h, w)

        rows[#rows + 1] = row_label
        matrix[row_label] = {}

        for _, l in ipairs(LENGTHS) do

          local board = {
            h = h,
            w = w,
            l = l,
            grade = grade.tag,
          }

          local result = pricer:evaluate(board)

          matrix[row_label][l] = {
            price = result.final_price_per_bf,
            multiplier = result.total_multiplier,
          }

          -- 🔎 Track minimum multiplier
          if result.total_multiplier < min_probe.total then
            min_probe.total = result.total_multiplier
            min_probe.board = {
              h = h,
              w = w,
              l = l,
              grade = grade.tag,
            }
            min_probe.result = result
          end
        end
      end
    end
  end

  return rows, matrix, min_probe
end

----------------------------------------------------------------
-- CSV Writer (UNCHANGED)
----------------------------------------------------------------

local function write_exact_csv(filename, rows, matrix)
  local file = io.open(filename, "w")

  file:write("HxW")
  for _, l in ipairs(LENGTHS) do
    file:write(string.format(",%d_price,%d_multiplier", l, l))
  end
  file:write("\n")

  for _, row_label in ipairs(rows) do
    file:write(row_label)

    for _, l in ipairs(LENGTHS) do
      local cell = matrix[row_label][l]
      file:write(string.format(
        ",%.6f,%.6f",
        cell.price,
        cell.multiplier
      ))
    end

    file:write("\n")
  end

  file:close()
end

----------------------------------------------------------------
-- Diagnostic Printer
----------------------------------------------------------------

local function print_min_probe(label, probe)
  if not probe or not probe.board then return end

  local b = probe.board
  local r = probe.result or {}
  local f = r.factors or {}

  local faces  = f.faces or {}
  local gradef = f.grade or {}
  local lengthf = f.length or {}

  print(string.format(
    "  MIN(%s) total=%.6f @ %sx%sx%s grade=%s",
    label,
    probe.total,
    b.h, b.w, b.l, b.grade
  ))

  print(string.format(
    "    faces=%.6f (width=%.6f height=%.6f waste=%.6f) grade=%.6f length=%.6f",
    tonumber(faces.multiplier_total) or -1,
    tonumber((faces.width or {}).multiplier_total) or -1,
    tonumber((faces.height or {}).multiplier_total) or -1,
    tonumber((faces.waste or {}).multiplier) or -1,
    tonumber(gradef.multiplier_total) or -1,
    tonumber(lengthf.multiplier_total) or -1
  ))
end

----------------------------------------------------------------
-- Run
----------------------------------------------------------------

print("Generating exact pricing surface dumps...")
print("Baseline $/bf:", pricer.config.baseline_price_per_bf)

local grades = sorted_grades_by_quality()

for _, grade in ipairs(grades) do

  print("\nGrade:", grade.tag)

  -- ACTUAL
  local rows_actual, matrix_actual, min_actual =
    generate_exact_surface(ACTUAL_HEIGHTS, ACTUAL_WIDTHS, grade)

  local file_actual =
    OUTPUT_DIR .. string.format("pricing_surface_exact_%s_actual.csv", grade.tag)

  write_exact_csv(file_actual, rows_actual, matrix_actual)
  print("  wrote:", file_actual)
  print_min_probe("actual", min_actual)

  -- NOMINAL
  local rows_nominal, matrix_nominal, min_nominal =
    generate_exact_surface(NOMINAL_HEIGHTS, NOMINAL_WIDTHS, grade)

  local file_nominal =
    OUTPUT_DIR .. string.format("pricing_surface_exact_%s_nominal.csv", grade.tag)

  write_exact_csv(file_nominal, rows_nominal, matrix_nominal)
  print("  wrote:", file_nominal)
  print_min_probe("nominal", min_nominal)
end

print("\nDone.")
