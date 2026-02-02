local Contract = require("presentation.exports.invoice.contract")

local M = {}

function M.build(input)
  Contract.validate(input)

  local rows = {}
  local totals = { count = 0, bf = 0, price = 0 }

  for _, b in ipairs(input.boards) do
    rows[#rows + 1] = {
      id          = b.id,
      h           = b.h,
      w           = b.w,
      l           = b.l,
      ct          = b.ct,
      grade       = b.grade,
      surface     = b.surface,
      note        = b.note,

      bf_each     = b.bf_each,
      bf_total    = b.bf_total,

      ea_price    = b.pricing.ea_price,
      bf_price    = b.pricing.bf_price,
      total_price = b.pricing.total_price,
    }

    totals.count = totals.count + b.ct
    totals.bf    = totals.bf + b.bf_total
    totals.price = totals.price + b.pricing.total_price
  end

  return { rows = rows, totals = totals }
end

return M
