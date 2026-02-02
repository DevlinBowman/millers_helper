local Layout = require("presentation.exports.invoice.layout")

local M = {}

local function cell(v, w, a)
  if a == "S" then return string.rep(" ", w) end
  v = tostring(v or "")
  return a == "L" and string.format("%-"..w.."s", v)
                 or string.format("%"..w.."s", v)
end

local function render(schema, values)
  local out = {}
  for _, c in ipairs(schema) do
    out[#out+1] = cell(values[c[1]], c[2], c[3])
  end
  return table.concat(out)
end

local function fmt(n, d)
  if not n then return "-" end
  return string.format("%."..(d or 2).."f", n)
end

function M.print(invoice)
  for _, r in ipairs(invoice.rows) do
    print(("="):rep(80))
    print(string.format(
      "Order Spec :: %-10s x%-3d pcs   Grade: %-3s   Note: %s",
      r.id, r.ct, r.grade or "-", r.note or ""
    ))
    print(string.format(
      "Deliverable :: %s x %s x %s ft   Surface: %s",
      fmt(r.h), fmt(r.w), fmt(r.l), r.surface or "-"
    ))
    print(("-"):rep(80))

    print(render(Layout.ROW1, {
      bf_price    = r.bf_price and "$"..fmt(r.bf_price) or "-",
      pcs         = "/BF",
      bf_each     = fmt(r.bf_each),
      bf_label    = "BF/pc",
      bf_total    = fmt(r.bf_total),
      total_label = "Total BF",
    }))

    print(render(Layout.ROW2, {
      ea_price    = r.ea_price and "$"..fmt(r.ea_price) or "-",
      ea_label    = "/pc",
      ct          = r.ct,
      pcs_label   = "pcs",
      total_price = "$"..fmt(r.total_price),
      total_label = "Total",
    }))
  end

  local t = invoice.totals
  print(("="):rep(80))
  print(string.format(
    "PROJECT TOTALS: %d pcs   %.2f BF   $%.2f total",
    t.count, t.bf, t.price
  ))
  print(("="):rep(80))
end

return M
