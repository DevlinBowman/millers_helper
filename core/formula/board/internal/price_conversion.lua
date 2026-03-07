-- core/formula/board/internal/price_conversion.lua
--
-- Board Price Conversion Formula
--
-- Pure unit-conversion math between:
--   • ea_price
--   • lf_price
--   • bf_price
--   • batch price

local Volume = require("core.formula.board.internal.volume")

local Convert = {}

------------------------------------------------
-- each -> bf
------------------------------------------------

---Convert each price to price per board foot.
---
---@param h number
---@param w number
---@param l number
---@param ea_price number
---@return number
function Convert.ea_to_bf(h, w, l, ea_price)
    local bf = Volume.bf(h, w, l)
    return ea_price / bf
end

------------------------------------------------
-- lf -> bf
------------------------------------------------

---Convert linear-foot price to price per board foot.
---
---@param h number
---@param w number
---@param lf_price number
---@return number
function Convert.lf_to_bf(h, w, lf_price)
    local bf_per_lf = Volume.bf_per_lf(h, w)
    return lf_price / bf_per_lf
end

------------------------------------------------
-- bf -> each
------------------------------------------------

---Convert price per board foot to each price.
---
---@param h number
---@param w number
---@param l number
---@param bf_price number
---@return number
function Convert.bf_to_ea(h, w, l, bf_price)
    local bf = Volume.bf(h, w, l)
    return bf_price * bf
end

------------------------------------------------
-- bf -> lf
------------------------------------------------

---Convert price per board foot to linear-foot price.
---
---@param h number
---@param w number
---@param bf_price number
---@return number
function Convert.bf_to_lf(h, w, bf_price)
    local bf_per_lf = Volume.bf_per_lf(h, w)
    return bf_price * bf_per_lf
end

------------------------------------------------
-- each -> batch
------------------------------------------------

---Convert each price to batch price.
---
---@param ea_price number
---@param ct number|nil
---@return number
function Convert.ea_to_batch(ea_price, ct)
    ct = ct or 1
    return ea_price * ct
end

return Convert
