local M = {}

local function assert_num(x, name)
  assert(type(x) == "number", name .. " must be a number")
end

local function derive_bf(board)
  return (board.h * board.w * board.l) / 12
end

function M.validate(input)
  assert(type(input) == "table", "invoice input must be table")
  assert(type(input.boards) == "table", "invoice.boards required")

  for i, b in ipairs(input.boards) do
    assert(type(b.id) == "string", "board.id required")
    assert_num(b.h, "board.h")
    assert_num(b.w, "board.w")
    assert_num(b.l, "board.l")
    assert_num(b.ct, "board.ct")
    assert(b.ct >= 1, "board.ct must be >= 1")

    if not b.bf_each then
      b.bf_each = derive_bf(b)
    end

    b.bf_total = b.bf_total or (b.bf_each * b.ct)
    b.pricing = b.pricing or {}
    b.pricing.total_price = b.pricing.total_price or 0
  end
end

return M
