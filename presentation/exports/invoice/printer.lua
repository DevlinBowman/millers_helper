-- presentation/exports/invoice/printer.lua
--
-- Invoice-style printer with wrapped line-items.
-- Line 1: ordered (nominal) item
-- Line 2: delivered dimensions + billing numbers
-- Uses trade-standard dimension notation.

local Signals = require("core.diagnostics.signals")

local M = {}

----------------------------------------------------------------
-- Column widths (single source of truth)
----------------------------------------------------------------

local COL = {
    qty    = 4,
    item   = 28,
    bf     = 10,
    rate   = 10,
    amount = 12,
}

local LINE_WIDTH =
    COL.qty +
    COL.item +
    COL.bf +
    COL.rate +
    COL.amount

----------------------------------------------------------------
-- Formatting helpers
----------------------------------------------------------------

local function rjust(w, s)
    return string.format("%" .. w .. "s", s)
end

local function ljust(w, s)
    return string.format("%-" .. w .. "s", s)
end

local function fmt(n, d)
    if n == nil then return "-" end
    return string.format("%." .. (d or 2) .. "f", n)
end

local function money(n)
    if n == nil then return "-" end
    return "$" .. string.format("%.2f", n)
end

-- Inches: .75"  5.5"
local function fmt_inches(n)
    if n == nil then return "-" end

    local s = string.format("%.3f", n)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    s = s:gsub("^0(%.)", "%1")

    return s .. '"'
end

-- Feet: 12'
local function fmt_feet(n)
    if n == nil then return "-" end

    if math.floor(n) == n then
        return tostring(n) .. "'"
    end

    local s = string.format("%.2f", n)
    s = s:gsub("0+$", ""):gsub("%.$", "")

    return s .. "'"
end

----------------------------------------------------------------
-- Signal printing (unchanged)
----------------------------------------------------------------

local function print_signal_summary(sig)
    if not sig or type(sig) ~= "table" then return end

    local e = Signals.count(sig, "error")
    local w = Signals.count(sig, "warn")
    local i = Signals.count(sig, "info")

    if (e + w + i) == 0 then return end

    print("")
    print("SIGNAL SUMMARY")
    print(string.rep("-", LINE_WIDTH))
    print(string.format("Errors: %d  Warnings: %d  Info: %d", e, w, i))
end

local function print_signals(sig)
    if not sig or type(sig.items) ~= "table" or #sig.items == 0 then return end

    print("")
    print("SIGNALS")
    print(string.rep("-", LINE_WIDTH))

    for _, s in ipairs(sig.items) do
        print(string.format("[%s] %s @ %s", s.level, s.code, s.path))
        print("  " .. tostring(s.message))
        if type(s.meta) == "table" then
            for k, v in pairs(s.meta) do
                print(string.format("  - %s: %s", k, v))
            end
        end
    end
end

----------------------------------------------------------------
-- Printer
----------------------------------------------------------------

--- @param invoice table
--- @param opts table|nil
function M.print(invoice, opts)
    opts = opts or {}

    invoice = invoice or {
        rows   = {},
        totals = { bf = 0, price = 0 },
    }

    ----------------------------------------------------------------
    -- Header
    ----------------------------------------------------------------

    print(string.rep("=", LINE_WIDTH))

    print(
        rjust(COL.qty, "QTY") ..
        " " ..
        ljust(COL.item - 1, "ITEM") ..
        rjust(COL.bf, "TOTAL BF") ..
        rjust(COL.rate, "RATE/BF") ..
        rjust(COL.amount, "AMOUNT")
    )

    print(string.rep("-", LINE_WIDTH))

    ----------------------------------------------------------------
    -- Rows
    ----------------------------------------------------------------

    for _, r in ipairs(invoice.rows or {}) do
        -- Line 1: ordered item (nominal)
        print(
            rjust(COL.qty, tostring(r.ct)) ..
            " " ..
            ljust(COL.item - 1, r.label)
        )

        -- Line 2: delivered dimensions + billing
        print(
            string.rep(" ", COL.qty + 1) ..
            ljust(
                COL.item - 1,
                "(actual) " ..
                fmt_inches(r.h) ..
                "x" ..
                fmt_inches(r.w) ..
                "x" ..
                fmt_feet(r.l)
            ) ..
            rjust(COL.bf, fmt(r.bf_total)) ..
            rjust(COL.rate, money(r.bf_price)) ..
            rjust(COL.amount, money(r.total_price))
        )

        print("") -- breathing room
    end

    ----------------------------------------------------------------
    -- Totals
    ----------------------------------------------------------------

    local t = invoice.totals or { bf = 0, price = 0 }

    print(string.rep("-", LINE_WIDTH))

    print(
        rjust(COL.qty + COL.item, "TOTALS") ..
        rjust(COL.bf, fmt(t.bf)) ..
        rjust(COL.rate, "") ..
        rjust(COL.amount, money(t.price))
    )

    print(string.rep("=", LINE_WIDTH))

    ----------------------------------------------------------------
    -- Signals
    ----------------------------------------------------------------

    if opts.show_signals
        or (invoice.signals and (invoice.signals.has_error or Signals.any(invoice.signals, "warn")))
    then
        print_signal_summary(invoice.signals)
        if opts.show_signal_items
            or (invoice.signals and invoice.signals.has_error)
        then
            print_signals(invoice.signals)
        end
    end
end

return M
