local TargetValue = require("core.domain.pricing.internal.target_value")

local ReverseOrderValue = {}

------------------------------------------------
-- Utilities
------------------------------------------------

local function resolve_board_bf(board)

    if type(board.bf) == "number" and board.bf > 0 then
        return board.bf
    end

    if type(board.bf_ea) == "number" and board.bf_ea > 0 then
        return board.bf_ea
    end

    local h = board.h or board.base_h
    local w = board.w or board.base_w
    local l = board.l

    if type(h) == "number"
        and type(w) == "number"
        and type(l) == "number"
    then
        return (h * w * l) / 12
    end

    return nil
end

------------------------------------------------
-- Strategy
------------------------------------------------

function ReverseOrderValue.run(env)

    local boards_env = env.boards
    assert(type(boards_env) == "table",
        "[pricing.reverse_order_value] boards envelope required")

    assert(boards_env.kind == "boards",
        "[pricing.reverse_order_value] boards.kind must be 'boards'")

    local boards = boards_env.items
    assert(type(boards) == "table",
        "[pricing.reverse_order_value] boards.items required")

    local target_total_value =
        TargetValue.resolve(env.source, env.opts)

    assert(type(target_total_value) == "number",
        "[pricing.reverse_order_value] target order value required")

    ------------------------------------------------
    -- compute total bf
    ------------------------------------------------

    local total_bf = 0
    local rows = {}

    for i, board in ipairs(boards) do

        local bf_ea = resolve_board_bf(board)

        assert(type(bf_ea) == "number" and bf_ea > 0,
            "[pricing.reverse_order_value] board bf could not be resolved")

        local ct = board.ct or 1
        local bf_batch = bf_ea * ct

        total_bf = total_bf + bf_batch

        rows[i] = {
            board = board,
            bf_batch = bf_batch
        }
    end

    assert(total_bf > 0,
        "[pricing.reverse_order_value] total board feet must be > 0")

    ------------------------------------------------
    -- compute base price
    ------------------------------------------------

    local base_price =
        target_total_value / total_bf

    ------------------------------------------------
    -- build result
    ------------------------------------------------

    local per_board = {}

    for i, row in ipairs(rows) do

        local bf_price = base_price

        per_board[i] = {
            label = row.board.label,

            suggested_price_per_bf   = bf_price,
            recommended_price_per_bf = bf_price,

            recommendation_mode = "reverse_order_value",
        }
    end

    return {
        basis = "reverse_order_value",
        per_board = per_board,

        meta = {
            target_total_value = target_total_value,
            total_bf           = total_bf,
            base_price         = base_price,
        },

        opts = env.opts or {},
    }
end

return ReverseOrderValue
