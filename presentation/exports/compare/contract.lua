-- presentation/exports/compare/contract.lua
--
-- Asserts structural eligibility for comparison.
-- No normalization. No mutation.

local CompareContract = {}

local function assertf(cond, msg)
    if not cond then error("[compare.contract] " .. msg, 3) end
end

local function is_table(v) return type(v) == "table" end

local function assert_board(b, ctx)
    assertf(is_table(b), ctx .. " must be a table")
    assertf(type(b.h) == "number", ctx .. ".h (number) required")
    assertf(type(b.w) == "number", ctx .. ".w (number) required")
    assertf(type(b.l) == "number", ctx .. ".l (number) required")
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
