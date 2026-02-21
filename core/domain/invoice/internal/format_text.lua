-- core/domain/invoice/internal/format_text.lua

local Format = {}

local COL = {
    qty    = 4,
    item   = 28,
    bf     = 10,
    rate   = 10,
    amount = 12,
}

local LINE_WIDTH =
    COL.qty + COL.item + COL.bf + COL.rate + COL.amount

local function rjust(w, s) return string.format("%" .. w .. "s", s) end
local function ljust(w, s) return string.format("%-" .. w .. "s", s) end

local function fmt(n)
    if n == nil then return "-" end
    return string.format("%.2f", n)
end

local function money(n)
    if n == nil then return "-" end
    return "$" .. string.format("%.2f", n)
end

function Format.render(invoice)
    local out = {}
    local function emit(line) out[#out + 1] = line end

    emit(string.rep("=", LINE_WIDTH))

    if invoice.header then
        emit("ORDER: " .. (invoice.header.order_id or "-"))
        emit("CUSTOMER: " .. (invoice.header.customer or "-"))
        emit(string.rep("-", LINE_WIDTH))
    end

    emit(
        rjust(COL.qty, "QTY") ..
        ljust(COL.item, " ITEM") ..
        rjust(COL.bf, "TOTAL BF") ..
        rjust(COL.rate, "RATE/BF") ..
        rjust(COL.amount, "AMOUNT")
    )

    emit(string.rep("-", LINE_WIDTH))

    for _, r in ipairs(invoice.rows or {}) do
        emit(
            rjust(COL.qty, tostring(r.ct or 0)) ..
            ljust(COL.item, " " .. (r.label or "")) ..
            rjust(COL.bf, fmt(r.bf_total)) ..
            rjust(COL.rate, money(r.bf_price)) ..
            rjust(COL.amount, money(r.total_price))
        )
    end

    emit(string.rep("-", LINE_WIDTH))

    local t = invoice.totals or {}

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

return Format
