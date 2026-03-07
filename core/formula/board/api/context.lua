-- core/formula/board/api/context.lua
--
-- Board Formula Calculation Context
--
-- Binds board dimensions and board-derived context to formula operations.
--
-- Responsibilities
--   • Hold resolved board dimensions
--   • Expose board-bound formula methods
--   • Forward operations into pure internal math modules
--
-- Notes
--
--   • This context does not mutate the input board
--   • This context does not cache results
--   • This context is a thin bound façade over pure formula modules

local Volume       = require("core.formula.board.internal.volume")
local Kerf         = require("core.formula.board.internal.kerf")
local PriceConvert = require("core.formula.board.internal.price_conversion")
local NominalDelta = require("core.formula.board.internal.n_delta_volume")

---@class FormulaBoardContext
---@field h number
---@field w number
---@field l number
---@field ct number
---@field base_h number|nil
---@field base_w number|nil
local Context = {}
Context.__index = Context

------------------------------------------------
-- constructor
------------------------------------------------

---Create a board formula context from a resolved board.
---
---Required board fields:
---  • h
---  • w
---  • l
---
---Optional board fields:
---  • ct
---  • base_h
---  • base_w
---
---Example:
---  local f = Context.new(board)
---
---@param board table
---@return FormulaBoardContext
function Context.new(board)

    assert(type(board) == "table", "Formula.board(): board table required")
    assert(type(board.h) == "number", "Formula.board(): board.h number required")
    assert(type(board.w) == "number", "Formula.board(): board.w number required")
    assert(type(board.l) == "number", "Formula.board(): board.l number required")

    return setmetatable({
        h = board.h,
        w = board.w,
        l = board.l,
        ct = board.ct or 1,
        base_h = board.base_h,
        base_w = board.base_w,
    }, Context)
end

------------------------------------------------
-- volume
------------------------------------------------

---Return board feet for one board.
---
---@return number
function Context:bf()
    return Volume.bf(self.h, self.w, self.l)
end

---Return board feet per linear foot.
---
---@return number
function Context:bf_per_lf()
    return Volume.bf_per_lf(self.h, self.w)
end

---Return total board feet for the bound batch count.
---
---@return number
function Context:bf_batch()
    return Volume.bf_batch(self.h, self.w, self.l, self.ct)
end

------------------------------------------------
-- waste
------------------------------------------------

---Return kerf waste model for the bound board.
---
---@param kerf number
---@return FormulaKerfResult
function Context:kerf(kerf)
    return Kerf.run(self.h, self.w, self.l, kerf)
end

------------------------------------------------
-- nominal delta
------------------------------------------------

---Return nominal-reference delta against delivered board volume.
---
---Requires:
---  • base_h
---  • base_w
---
---Return nominal-reference delta against delivered board volume.
---
---Requires:
---  • base_h
---  • base_w
---
---@return FormulaNominalDeltaResult
function Context:n_delta()

    assert(type(self.base_h) == "number", "Context:n_delta(): base_h number required")
    assert(type(self.base_w) == "number", "Context:n_delta(): base_w number required")

    local ratio, percent =
        NominalDelta.run(self.base_h, self.base_w, self.h, self.w, self.l)

    return {
        delta_ratio   = ratio,
        delta_percent = percent
    }

end

------------------------------------------------
-- price conversions
------------------------------------------------

---Convert each price to price per board foot.
---
---@param ea_price number
---@return number
function Context:ea_to_bf(ea_price)
    return PriceConvert.ea_to_bf(self.h, self.w, self.l, ea_price)
end

---Convert linear-foot price to price per board foot.
---
---@param lf_price number
---@return number
function Context:lf_to_bf(lf_price)
    return PriceConvert.lf_to_bf(self.h, self.w, lf_price)
end

---Convert price per board foot to each price.
---
---@param bf_price number
---@return number
function Context:bf_to_ea(bf_price)
    return PriceConvert.bf_to_ea(self.h, self.w, self.l, bf_price)
end

---Convert price per board foot to linear-foot price.
---
---@param bf_price number
---@return number
function Context:bf_to_lf(bf_price)
    return PriceConvert.bf_to_lf(self.h, self.w, bf_price)
end

---Convert each price to batch price using bound count.
---
---@param ea_price number
---@return number
function Context:ea_to_batch(ea_price)
    return PriceConvert.ea_to_batch(ea_price, self.ct)
end


return Context
