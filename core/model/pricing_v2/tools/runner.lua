-- core/model/pricing_v2/tools/runner.lua
--
-- Monolithic runner for pricing_v2 tools.
-- Outputs are intended to be identical to the original two scripts.

local GradeEnum   = require("core.enums.grades")
local BoardPricer = require("core.model.pricing_v2.board_pricer")

local Runner = {}

----------------------------------------------------------------
-- Config normalize (prevents nil crashes + ensures baseline)
----------------------------------------------------------------

local function normalize_config(cfg)
  cfg = cfg or {}

  -- baseline
  if cfg.baseline_price_per_bf == nil then
    cfg.baseline_price_per_bf = 2.00
  end

  -- regimes
  cfg.actual = cfg.actual or {}
  cfg.actual.heights = cfg.actual.heights or { 1, 2, 4, 6, 8 }
  cfg.actual.widths  = cfg.actual.widths  or { 1, 2, 4, 6, 8, 10, 12 }

  cfg.nominal = cfg.nominal or {}
  cfg.nominal.heights = cfg.nominal.heights or { 0.75, 1.5, 3.5, 5.5, 7.25 }
  cfg.nominal.widths  = cfg.nominal.widths  or { 0.75, 1.5, 3.5, 5.5, 7.25, 9.25, 11.25 }

  -- lengths (keep the two-tool mismatch intentionally)
  cfg.surface_lengths = cfg.surface_lengths or { 8, 10, 12, 16, 20 }
  cfg.extract_lengths = cfg.extract_lengths or { 6, 8, 10, 12, 16 }

  -- output
  if cfg.output_dir == nil then
    cfg.output_dir = os.getenv("HOME") .. "/Desktop/board_data/in_data/"
  end

  return cfg
end

local function load_config()
  local ok, cfg = pcall(require, "core.model.pricing_v2.tools.config")
  if not ok then
    -- Fall back to defaults if module missing/misnamed.
    return normalize_config(nil)
  end
  return normalize_config(cfg)
end

----------------------------------------------------------------
-- Grade sorting (IDENTICAL)
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
-- ANSI Color Codes (IDENTICAL)
----------------------------------------------------------------

local RESET  = "\27[0m"
local BLUE   = "\27[34m"
local GREEN  = "\27[32m"
local YELLOW = "\27[33m"
local RED    = "\27[31m"
local ORANGE = "\27[38;5;208m"

local function colorize_price(value)
  if value < 2.0 then
    return BLUE .. string.format("%6.2f", value) .. RESET
  elseif value < 4.0 then
    return GREEN .. string.format("%6.2f", value) .. RESET
  elseif value < 5.0 then
    return YELLOW .. string.format("%6.2f", value) .. RESET
  elseif value < 6.0 then
    return ORANGE .. string.format("%6.2f", value) .. RESET
  else
    return RED .. string.format("%6.2f", value) .. RESET
  end
end

----------------------------------------------------------------
-- Shared print helpers (IDENTICAL)
----------------------------------------------------------------

local function printf(fmt, ...)
  io.write(string.format(fmt, ...))
end

local function print_separator(width)
  print(string.rep("-", width))
end

----------------------------------------------------------------
-- PRINT TOOL (IDENTICAL to pricing_surface_dump.lua)
----------------------------------------------------------------

local function print_surface(pricer, title, heights, widths, lengths, grade)
  print()
  print("---- " .. title .. " ----")

  local col_width = 20
  local row_label_width = 16
  local total_width = row_label_width + (#lengths * col_width)

  print_separator(total_width)

  printf("%-" .. row_label_width .. "s", "HxW \\ L")
  for _, l in ipairs(lengths) do
    printf("%-" .. col_width .. "s", l .. "ft")
  end
  print()

  print_separator(total_width)

  for _, h in ipairs(heights) do
    for _, w in ipairs(widths) do
      -- enforce realistic lumber orientation
      if h <= 8 and w <= 12 and h <= w then

        printf("%-" .. row_label_width .. "s",
          string.format("%.2fx%.2f", h, w)
        )

        for _, l in ipairs(lengths) do
          local board = {
            h = h,
            w = w,
            l = l,
            grade = grade.tag,
          }

          local result = pricer:evaluate(board)
          local colored_price = colorize_price(result.final_price_per_bf)

          local cell = string.format(
            "%s | x%.2f",
            colored_price,
            result.total_multiplier
          )

          printf("%-" .. col_width .. "s", cell)
        end

        print()
      end
    end
  end

  print_separator(total_width)
end

function Runner.surface_print()
  local cfg = load_config()

  local pricer = BoardPricer.new({
    baseline_price_per_bf = cfg.baseline_price_per_bf,
  })

  print("==============================================================")
  print("DUAL DIMENSION PRICING SURFACE")
  print("Baseline $/bf:", pricer.config.baseline_price_per_bf)
  print("==============================================================")

  local grades = sorted_grades_by_quality()

  for _, grade in ipairs(grades) do
    print()
    print(string.format(
      "GRADE: %-3s  |  VALUE: %.2f",
      grade.tag,
      grade.value
    ))

    print_surface(
      pricer,
      "ACTUAL DIMENSIONS",
      cfg.actual.heights,
      cfg.actual.widths,
      cfg.surface_lengths,
      grade
    )

    print_surface(
      pricer,
      "NOMINAL DIMENSIONS",
      cfg.nominal.heights,
      cfg.nominal.widths,
      cfg.surface_lengths,
      grade
    )
  end

  print("\n==============================================================")
  print("END")
  print("==============================================================")
end

----------------------------------------------------------------
-- EXTRACT TOOL (IDENTICAL to printing_surface_dump_extract.lua)
----------------------------------------------------------------

local function generate_exact_surface(pricer, heights, widths, lengths, grade)
  local rows = {}
  local matrix = {}

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

        for _, l in ipairs(lengths) do
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

          if result.total_multiplier < min_probe.total then
            min_probe.total = result.total_multiplier
            min_probe.board = {
              h = h, w = w, l = l, grade = grade.tag,
            }
            min_probe.result = result
          end
        end
      end
    end
  end

  return rows, matrix, min_probe
end

local function write_exact_csv(filename, rows, matrix, lengths)
  local file = io.open(filename, "w")

  file:write("HxW")
  for _, l in ipairs(lengths) do
    file:write(string.format(",%d_price,%d_multiplier", l, l))
  end
  file:write("\n")

  for _, row_label in ipairs(rows) do
    file:write(row_label)

    for _, l in ipairs(lengths) do
      local cell = matrix[row_label][l]
      file:write(string.format(",%.6f,%.6f", cell.price, cell.multiplier))
    end

    file:write("\n")
  end

  file:close()
end

local function print_min_probe(label, probe)
  if not probe or not probe.board then return end

  local b = probe.board
  local r = probe.result or {}
  local f = r.factors or {}

  local faces   = f.faces or {}
  local gradef  = f.grade or {}
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

function Runner.surface_extract()
  local cfg = load_config()

  local output_dir = cfg.output_dir
  os.execute("mkdir -p " .. output_dir)

  local pricer = BoardPricer.new({
    baseline_price_per_bf = cfg.baseline_price_per_bf,
  })

  print("Generating exact pricing surface dumps...")
  print("Baseline $/bf:", pricer.config.baseline_price_per_bf)

  local grades = sorted_grades_by_quality()

  for _, grade in ipairs(grades) do
    print("\nGrade:", grade.tag)

    -- ACTUAL
    local rows_actual, matrix_actual, min_actual =
      generate_exact_surface(pricer, cfg.actual.heights, cfg.actual.widths, cfg.extract_lengths, grade)

    local file_actual =
      output_dir .. string.format("pricing_surface_exact_%s_actual.csv", grade.tag)

    write_exact_csv(file_actual, rows_actual, matrix_actual, cfg.extract_lengths)
    print("  wrote:", file_actual)
    print_min_probe("actual", min_actual)

    -- NOMINAL
    local rows_nominal, matrix_nominal, min_nominal =
      generate_exact_surface(pricer, cfg.nominal.heights, cfg.nominal.widths, cfg.extract_lengths, grade)

    local file_nominal =
      output_dir .. string.format("pricing_surface_exact_%s_nominal.csv", grade.tag)

    write_exact_csv(file_nominal, rows_nominal, matrix_nominal, cfg.extract_lengths)
    print("  wrote:", file_nominal)
    print_min_probe("nominal", min_nominal)
  end

  print("\nDone.")
end

----------------------------------------------------------------
-- Dispatcher
----------------------------------------------------------------

function Runner.run(task)
  if task == "print" then
    return Runner.surface_print()
  elseif task == "extract" then
    return Runner.surface_extract()
  else
    error("Unknown task: use 'print' or 'extract'")
  end
end

return Runner
