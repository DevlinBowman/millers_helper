-- core/utils/board_attr_conversion.lua

local util = require("core.model.board.internal.utils.helpers")

local Convert = {}

local ROUND_DECIMALS = 2

local function auto_round(value)
    return util.round_number(value, ROUND_DECIMALS)
end

-- ------------------------------------------------------------
-- Private scalar helpers (NO validation, NO rounding policy)
-- ------------------------------------------------------------

local function bf_raw(h, w, l)
    return h * w * l / 12
end

local function bf_per_lf_raw(h, w)
    return h * w / 12
end

-- ------------------------------------------------------------
-- Public API (board-based, validated)
-- ------------------------------------------------------------

-- calculate board feet (rounded)
--- @param board Board
--- @return number bf -- board feet, rounded
function Convert.bf(board)
    util.check_board_attrs(board, "h", "w", "l")

    local bf = bf_raw(board.h, board.w, board.l)
    return auto_round(bf)
end

-- board feet per linear foot (UNROUNDED, intermediate)
--- @param board table
--- @return number bf_per_lf -- board feet per linear foot
function Convert.bf_per_lf(board)
    util.check_board_attrs(board, "h", "w")

    return bf_per_lf_raw(board.h, board.w)
end

-- each price -> price per board foot (rounded)
--- @param board table
--- @return number price_per_bf
function Convert.ea_price_to_bf_price(board)
    util.check_board_attrs(board, "h", "w", "l", "ea_price")
    assert(board.ea_price >= 0, "ea_price_to_bf_price(): ea_price must be non-negative")

    local bf = bf_raw(board.h, board.w, board.l)
    local price_per_bf = board.ea_price / bf

    return auto_round(price_per_bf)
end

--- linear-foot price -> price per board foot (rounded)
--- @param board table
--- @return number bf_price
function Convert.lf_price_to_bf_price(board)
    util.check_board_attrs(board, "h", "w", "lf_price")
    assert(board.lf_price >= 0, "lf_price_to_bf_price(): lf_price must be non-negative")

    local bf_per_lf = bf_per_lf_raw(board.h, board.w)
    return auto_round(board.lf_price / bf_per_lf)
end

--- price per board foot -> each price (rounded)
function Convert.bf_price_to_ea_price(board)
    util.check_board_attrs(board, "h", "w", "l", "bf_price")
    assert(board.bf_price >= 0, "bf_price_to_ea_price(): bf_price must be non-negative")

    local bf = bf_raw(board.h, board.w, board.l)
    return auto_round(board.bf_price * bf)
end

--- price per board foot -> linear-foot price (rounded)
function Convert.bf_price_to_lf_price(board)
    util.check_board_attrs(board, "h", "w", "bf_price")
    assert(board.bf_price >= 0, "bf_price_to_lf_price(): bf_price must be non-negative")

    local bf_per_lf = bf_per_lf_raw(board.h, board.w)
    return auto_round(board.bf_price * bf_per_lf)
end

return Convert
