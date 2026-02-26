local Presets = {}

----------------------------------------------------------------
-- Local helpers
----------------------------------------------------------------

local function dim_with_tag(board)
    return string.format(
        "%sx%sx%s%s",
        board.base_h,
        board.base_w,
        board.l,
        board.tag or ""
    )
end

local function safe_number(v, decimals)
    return string.format("%." .. (decimals or 2) .. "f", v or 0)
end

----------------------------------------------------------------
-- 1) BOARD LABEL (NO CT)
--
-- Intended for invoice display where QTY is shown separately
-- and the canonical xN portion is omitted.
--
-- Example:
--
--   local line = Fmt.format(board, "board_label_no_ct")
--
-- Output:
--     19 1x6x12n CC
--
----------------------------------------------------------------

Presets.board_label_no_ct = {
    separator = " ",
    columns = {
    --     {
    --         field = "ct",
    --         format = function(v)
    --             return string.format("%4d", v or 1)
    --         end
    --     },
        {
            compute = function(board)
                return dim_with_tag(board)
            end
        },
        { field = "species" },
        { field = "grade" },
        { field = "moisture" },
        { field = "surface" },
    }
}

----------------------------------------------------------------
-- 2) BOARD DEBUG
--
-- Developer-oriented projection.
--
-- Example:
--
--   local line = Fmt.format(board, "board_debug")
--
-- Output:
--   id=1x6x12n x19 | bf_ea=4.13 | bf_batch=78.47 | tag=n
--
----------------------------------------------------------------

Presets.board_debug = {
    separator = " | ",
    columns = {
        {
            compute = function(board)
                return "id=" .. tostring(board.id or "")
            end
        },
        {
            compute = function(board)
                return "bf_ea=" .. safe_number(board.bf_ea, 2)
            end
        },
        {
            compute = function(board)
                return "bf_batch=" .. safe_number(board.bf_batch, 2)
            end
        },
        {
            compute = function(board)
                return "tag=" .. tostring(board.tag or "")
            end
        },
    }
}

return Presets
