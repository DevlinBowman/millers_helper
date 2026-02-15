-- core/model/board/board_normalize.lua
--
-- Dimension normalization and nominal mapping ONLY

local Util = require("core.model.board.internal.utils.helpers")

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

-- expose for coercion layer
Normalize.NOMINAL_FACE_MAP = NOMINAL_FACE_MAP

----------------------------------------------------------------
-- Face resolution
----------------------------------------------------------------

function Normalize.face_from_tag(base_h, base_w, tag)
    assert(type(base_h) == "number" and base_h > 0, "base_h must be positive")
    assert(type(base_w) == "number" and base_w > 0, "base_w must be positive")

    -- nominal
    if tag == "n" then
        return NOMINAL_FACE_MAP[base_h] or base_h,
               NOMINAL_FACE_MAP[base_w] or base_w
    end

    -- freeform or custom
    if tag == nil or tag == "" or tag == "f" or tag == "c" then
        return base_h, base_w
    end

    error("unknown board tag: " .. tostring(tag))
end

----------------------------------------------------------------
-- Nominal reference volume
----------------------------------------------------------------

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

function Normalize.nominal_delta(board)
    assert(type(board) == "table", "nominal_delta(): board required")

    -- custom boards do not have nominal reference
    if board.tag == "c" then
        return nil
    end

    local base_h = board.base_h
    local base_w = board.base_w
    local l      = board.l
    local bf_ea  = board.bf_ea

    if base_h and base_w and l then
        local base_bf = (base_h * base_w * l) / 12

        if base_bf > 0 then
            local delta = (bf_ea - base_bf) / base_bf
            return Util.round_number(delta, 2)
        end
    end

    return 0
end

return Normalize
