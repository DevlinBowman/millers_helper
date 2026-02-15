-- core/model/board/derive.lua

local Normalize = require("core.model.board.internal.normalize")
local Convert   = require("core.model.board.internal.attr_conversion")
local Util      = require("core.model.board.internal.utils.helpers")


local Derive = {}

local function resolve_pricing(board)
    local bf_price = board.bf_price

    if bf_price == nil then
        if board.ea_price then
            bf_price = Convert.ea_price_to_bf_price(board)
        elseif board.lf_price then
            bf_price = Convert.lf_price_to_bf_price(board)
        end
    end

    if bf_price == nil then
        return
    end

    board.bf_price = bf_price
    board.ea_price = Convert.bf_price_to_ea_price(board)
    board.lf_price = Convert.bf_price_to_lf_price(board)

    board.batch_price = Util.round_number(
        bf_price * board.bf_batch,
        2
    )
end

function Derive.run(board)
    board.h, board.w = Normalize.face_from_tag(
        board.base_h,
        board.base_w,
        board.tag
    )

    board.bf_ea     = Convert.bf(board)
    board.bf_per_lf = Convert.bf_per_lf(board)
    board.bf_batch  = board.bf_ea * board.ct

    resolve_pricing(board)

    board.n_delta_vol = Normalize.nominal_delta(board)

    return board
end

return Derive
