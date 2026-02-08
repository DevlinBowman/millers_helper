-- core/invoice/formats/text.lua
--
-- Text formatter for InvoiceModel.
-- NO I/O. NO printing.

local Signals = require("core.diagnostics.signals")

local Text = {}

----------------------------------------------------------------
-- Column widths
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

local function rjust(w, s) return string.format("%" .. w .. "s", s) end
local function ljust(w, s) return string.format("%-" .. w .. "s", s) end

local function fmt(n, d)
    if n == nil then return "-" end
    return string.format("%." .. (d or 2) .. "f", n)
end

local function money(n)
    if n == nil then return "-" end
    return "$" .. string.format("%.2f", n)
end

local function fmt_inches(n)
    if n == nil then return "-" end
    local s = string.format("%.3f", n)
    s = s:gsub("0+$", ""):gsub("%.$", ""):gsub("^0(%.)", "%1")
    return s .. '"'
end

local function fmt_feet(n)
    if n == nil then return "-" end
    if math.floor(n) == n then return tostring(n) .. "'" end
    local s = string.format("%.2f", n)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s .. "'"
end

----------------------------------------------------------------
-- Formatter
----------------------------------------------------------------

function Text.format(invoice, opts)
    opts = opts or {}

    local out = {}

    local function emit(line)
        out[#out + 1] = line
    end

    invoice = invoice or { rows = {}, totals = { bf = 0, price = 0 } }

    emit(string.rep("=", LINE_WIDTH))
    emit(
        rjust(COL.qty, "QTY") ..
        " " ..
        ljust(COL.item - 1, "ITEM") ..
        rjust(COL.bf, "TOTAL BF") ..
        rjust(COL.rate, "RATE/BF") ..
        rjust(COL.amount, "AMOUNT")
    )
    emit(string.rep("-", LINE_WIDTH))

    for _, r in ipairs(invoice.rows or {}) do
        emit(
            rjust(COL.qty, tostring(r.ct)) ..
            " " ..
            ljust(COL.item - 1, r.label)
        )

        emit(
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

        emit("")
    end

    local t = invoice.totals or { bf = 0, price = 0 }

    emit(string.rep("-", LINE_WIDTH))
    emit(
        rjust(COL.qty + COL.item, "TOTALS") ..
        rjust(COL.bf, fmt(t.bf)) ..
        rjust(COL.rate, "") ..
        rjust(COL.amount, money(t.price))
    )
    emit(string.rep("=", LINE_WIDTH))

    return {
        kind  = "text",
        lines = out,
    }
end

return Text
