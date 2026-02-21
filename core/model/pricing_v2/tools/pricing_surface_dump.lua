-- tools/pricing_surface_dump.lua
--
-- Dual regime pricing surface (color-coded $/bf)

local GradeEnum   = require("core.enums.grades")
local BoardPricer = require("core.model/pricing_v2/board_pricer")

local pricer = BoardPricer.new({
  baseline_price_per_bf = 2.00,
})

----------------------------------------------------------------
-- ANSI Color Codes
----------------------------------------------------------------

local RESET  = "\27[0m"
local BLUE   = "\27[34m"
local GREEN  = "\27[32m"
local YELLOW = "\27[33m"
local RED    = "\27[31m"
local ORANGE = "\27[38;5;208m"  -- 256-color orange

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
-- Dimension Regimes
----------------------------------------------------------------

local ACTUAL_HEIGHTS = { 1, 2, 4, 6, 8 }
local ACTUAL_WIDTHS  = { 1, 2, 4, 6, 8, 10, 12 }

local NOMINAL_HEIGHTS = { 0.75, 1.5, 3.5, 5.5, 7.25 }
local NOMINAL_WIDTHS  = { 0.75, 1.5, 3.5, 5.5, 7.25, 9.25, 11.25 }

local LENGTHS = {  8, 10, 12, 16, 20 }

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function printf(fmt, ...)
  io.write(string.format(fmt, ...))
end

local function print_separator(width)
  print(string.rep("-", width))
end

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

local function print_surface(title, heights, widths, grade)
  print()
  print("---- " .. title .. " ----")

  local col_width = 20
  local row_label_width = 16
  local total_width = row_label_width + (#LENGTHS * col_width)

  print_separator(total_width)

  printf("%-" .. row_label_width .. "s", "HxW \\ L")
  for _, l in ipairs(LENGTHS) do
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

        for _, l in ipairs(LENGTHS) do

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

----------------------------------------------------------------
-- Run
----------------------------------------------------------------

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

  print_surface("ACTUAL DIMENSIONS", ACTUAL_HEIGHTS, ACTUAL_WIDTHS, grade)
  print_surface("NOMINAL DIMENSIONS", NOMINAL_HEIGHTS, NOMINAL_WIDTHS, grade)
end

print("\n==============================================================")
print("END")
print("==============================================================")
