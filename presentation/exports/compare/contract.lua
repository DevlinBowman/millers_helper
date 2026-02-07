-- presentation/exports/compare/contract.lua
--
-- Asserts structural eligibility for comparison.
-- Expects the same grouped Board shape as invoice:
--   board.physical + board.pricing
--
-- No normalization. No mutation.

local CompareContract = {}

local function assertf(cond, msg)
    if not cond then error("[compare.contract] " .. msg, 3) end
end

local function is_table(v) return type(v) == "table" end

local function assert_board(b, ctx)
    assertf(is_table(b), ctx .. " must be a table")
    assertf(type(b.id) == "string" or b.id == nil, ctx .. ".id must be string when present")

    assertf(is_table(b.physical), ctx .. ".physical required")
    assertf(is_table(b.pricing),  ctx .. ".pricing required")

    local p = b.physical
    assertf(type(p.h) == "number", ctx .. ".physical.h (number) required")
    assertf(type(p.w) == "number", ctx .. ".physical.w (number) required")
    assertf(type(p.l) == "number", ctx .. ".physical.l (number) required")

    -- ct/bf fields are used by the compare model for units + totals
    assertf(type(p.ct) == "number" or p.ct == nil, ctx .. ".physical.ct must be number when present")
    assertf(type(p.bf_ea) == "number" or p.bf_ea == nil, ctx .. ".physical.bf_ea must be number when present")
    assertf(type(p.bf_batch) == "number" or p.bf_batch == nil, ctx .. ".physical.bf_batch must be number when present")
end

function CompareContract.validate(input)
    assertf(is_table(input), "input must be table")
    assertf(is_table(input.order), "input.order required")
    assertf(is_table(input.order.boards), "order.boards required")

    for i, b in ipairs(input.order.boards) do
        assert_board(b, "order.boards[" .. i .. "]")
    end

    assertf(is_table(input.sources), "input.sources required")

    for si, src in ipairs(input.sources) do
        assertf(type(src.name) == "string", "sources[" .. si .. "].name required")
        assertf(is_table(src.boards), "sources[" .. si .. "].boards required")
        for bi, b in ipairs(src.boards) do
            assert_board(b, src.name .. ".boards[" .. bi .. "]")
        end
    end
end

return CompareContract
