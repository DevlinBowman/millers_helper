-- core/formula/board/internal/volume.lua
--
-- Board Volume Formula
--
-- Pure board-foot volume math.
--
-- Responsibilities
--   • Compute board feet for one board
--   • Compute board feet per linear foot
--   • Compute board feet for a batch

local Volume = {}

------------------------------------------------
-- one board
------------------------------------------------

---Return board feet for one board.
---
---@param h number
---@param w number
---@param l number
---@return number
function Volume.bf(h, w, l)
    assert(type(h) == "number", "Volume.bf(): h number required")
    assert(type(w) == "number", "Volume.bf(): w number required")
    assert(type(l) == "number", "Volume.bf(): l number required")
    return (h * w * l) / 12
end

------------------------------------------------
-- per linear foot
------------------------------------------------

---Return board feet per linear foot.
---
---@param h number
---@param w number
---@return number
function Volume.bf_per_lf(h, w)
    assert(type(h) == "number", "Volume.bf_per_lf(): h number required")
    assert(type(w) == "number", "Volume.bf_per_lf(): w number required")
    return (h * w) / 12
end

------------------------------------------------
-- batch
------------------------------------------------

---Return board feet for a batch.
---
---@param h number
---@param w number
---@param l number
---@param ct number|nil
---@return number
function Volume.bf_batch(h, w, l, ct)
    ct = ct or 1
    return Volume.bf(h, w, l) * ct
end

return Volume
