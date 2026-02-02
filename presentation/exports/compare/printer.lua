-- presentation/exports/compare/printer.lua
--
-- Stdout renderer for ComparisonModel.

local CompareLayout = require("presentation.exports.compare.layout")

local ComparePrinter = {}

local function cell(v, w, a)
    v = tostring(v or "-")
    if a == "L" then
        return string.format("%-" .. w .. "s", v)
    else
        return string.format("%" .. w .. "s", v)
    end
end

local function render_header()
    local out = {}
    for _, c in ipairs(CompareLayout.header) do
        table.insert(out, cell(c[1], c[2], c[3]))
    end
    print(table.concat(out, " "))
end

function ComparePrinter.print(model)
    for _, row in ipairs(model.rows) do
        print(("="):rep(110))
        print(string.format(
            "Order Board %s — %sx%sx%s ft  (%d pcs)",
            row.order_board.id or "?",
            row.order_board.h,
            row.order_board.w,
            row.order_board.l,
            row.order_board.ct or 1
        ))

        render_header()

        for src, data in pairs(row.offers) do
            local p = data.pricing or {}
            local m = data.matched_offer

            print(string.format(
                "%-15s %-28s %10s %10s %10s %12s %-10s",
                src,
                m and (m.id or "?") or "n/a",
                p.ea and string.format("$%.2f", p.ea) or "-",
                p.lf and string.format("$%.2f", p.lf) or "-",
                p.bf and string.format("$%.2f", p.bf) or "-",
                p.total and string.format("$%.2f", p.total) or "-",
                data.meta.match_type
            ))
        end
    end

    print(("="):rep(110))
end

return ComparePrinter
