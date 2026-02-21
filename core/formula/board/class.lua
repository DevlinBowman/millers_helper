-- core/formula/board/class.lua
--
-- BoardFormula
--
-- Lightweight calculation façade over board formula modules.
-- Pure. No mutation. No side effects.

local Volume         = require("core.formula.board.volume")
local Kerf           = require("core.formula.board.kerf")
local PriceConvert   = require("core.formula.board.price_conversion")
local NominalDelta   = require("core.formula.board.n_delta_volume")

local BoardFormula = {}
BoardFormula.__index = BoardFormula

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function BoardFormula.new(board)
    assert(type(board) == "table", "BoardFormula.new(): board required")
    assert(board.h and board.w and board.l, "BoardFormula.new(): board missing dimensions")

    return setmetatable({
        board = board
    }, BoardFormula)
end

----------------------------------------------------------------
-- Volume
----------------------------------------------------------------

function BoardFormula:bf()
    return Volume.bf(self.board.h, self.board.w, self.board.l)
end

function BoardFormula:bf_per_lf()
    return Volume.bf_per_lf(self.board.h, self.board.w)
end

function BoardFormula:batch_bf()
    return Volume.batch_bf(
        self.board.h,
        self.board.w,
        self.board.l,
        self.board.ct or 1
    )
end

----------------------------------------------------------------
-- Kerf
----------------------------------------------------------------

function BoardFormula:kerf(kerf_in)
    return Kerf.run(self.board, kerf_in)
end

----------------------------------------------------------------
-- Nominal Delta (full baseline)
----------------------------------------------------------------

function BoardFormula:n_delta()
    assert(self.board.base_h and self.board.base_w, "n_delta(): base dimensions required")

    local ratio, percent = NominalDelta.run(
        self.board.base_h,
        self.board.base_w,
        self.board.h,
        self.board.w,
        self.board.l
    )

    return {
        delta_ratio   = ratio,
        delta_percent = percent
    }
end

----------------------------------------------------------------
-- Pricing Conversions
----------------------------------------------------------------

function BoardFormula:ea_to_bf(ea_price)
    return PriceConvert.ea_to_bf(
        self.board.h,
        self.board.w,
        self.board.l,
        ea_price
    )
end

function BoardFormula:lf_to_bf(lf_price)
    return PriceConvert.lf_to_bf(
        self.board.h,
        self.board.w,
        lf_price
    )
end

function BoardFormula:bf_to_ea(bf_price)
    return PriceConvert.bf_to_ea(
        self.board.h,
        self.board.w,
        self.board.l,
        bf_price
    )
end

function BoardFormula:bf_to_lf(bf_price)
    return PriceConvert.bf_to_lf(
        self.board.h,
        self.board.w,
        bf_price
    )
end

return BoardFormula
