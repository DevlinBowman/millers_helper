-- core/board/board_normalize.lua
-- Dimension normalization and nominal mapping ONLY
--
-- Responsibility:
--   • Interpret declared dimensions
--   • Resolve working (actual) dimensions
--   • Compare nominal vs delivered physical volume
--
-- This module contains NO pricing logic
-- and NO ledger / context concerns.
--
local Util = require("core.model.board.utils.helpers")

local Normalize = {}

-- industry nominal → actual (inches)
local NOMINAL_FACE_MAP = {
    [1]  = 0.75,
    [2]  = 1.5,
    [3]  = 2.5,
    [4]  = 3.5,
    [6]  = 5.5,
    [8]  = 7.25,
    [10] = 9.25,
    [12] = 11.25,
}

----------------------------------------------------------------
-- Face resolution
----------------------------------------------------------------

--- Resolve working face from declared dimensions + tag
--- Declared dimensions may be nominal or actual.
--- Tag controls interpretation:
---   "n" => map nominal to actual
---   nil / "" / "f" => treat declared as actual/freeform
---
--- @param base_h number
--- @param base_w number
--- @param tag string?
--- @return number h_actual
--- @return number w_actual
function Normalize.face_from_tag(base_h, base_w, tag)
    assert(type(base_h) == "number" and base_h > 0, "base_h must be positive")
    assert(type(base_w) == "number" and base_w > 0, "base_w must be positive")

    if tag == "n" then
        return NOMINAL_FACE_MAP[base_h] or base_h,
               NOMINAL_FACE_MAP[base_w] or base_w
    end

    if tag == nil or tag == "" or tag == "f" then
        return base_h, base_w
    end

    error("unknown board tag: " .. tostring(tag))
end

----------------------------------------------------------------
-- Nominal reference volume
----------------------------------------------------------------

--- Nominal reference board-feet
--- Used as a baseline for delivered vs declared comparison.
---
--- @param base_h number
--- @param base_w number
--- @param l number
--- @return number bf
function Normalize.nominal_bf(base_h, base_w, l)
    assert(type(base_h) == "number" and base_h > 0, "base_h must be positive")
    assert(type(base_w) == "number" and base_w > 0, "base_w must be positive")
    assert(type(l) == "number" and l > 0, "l must be positive")

    local nh = NOMINAL_FACE_MAP[base_h] or base_h
    local nw = NOMINAL_FACE_MAP[base_w] or base_w

    return (nh * nw * l) / 12
end

----------------------------------------------------------------
-- Nominal vs delivered delta
----------------------------------------------------------------

--- Compute delivered volume delta relative to nominal declaration.
---
--- Delta is expressed as:
---   (delivered - nominal) / nominal
---
--- Returns:
---   • number in range (-∞, +∞) when nominal > 0
---   • 0 when nominal volume is zero or invalid
---
--- @param board table
--- @return number delta
function Normalize.nominal_delta(board)
    assert(type(board) == "table", "nominal_delta(): board required")

    local base_h = board.base_h
    local base_w = board.base_w
    local l      = board.l
    local bf_ea  = board.bf_ea
    local n_delta_vol

    if base_h and base_w and l then
        local base_bf = (base_h * base_w * board.l) / 12
        local delivered_bf = bf_ea

        if base_bf > 0 then
            local delta = (delivered_bf - base_bf) / base_bf
            n_delta_vol = Util.round_number(delta, 2)
        else
            n_delta_vol = 0
        end
    end
    return n_delta_vol
end

return Normalize
