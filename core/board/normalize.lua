-- core/board/board_normalize.lua
-- Dimension normalization and nominal mapping ONLY

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

--- Nominal reference bf (used for delta comparison)
function Normalize.nominal_bf(base_h, base_w, l)
    local nh = NOMINAL_FACE_MAP[base_h] or base_h
    local nw = NOMINAL_FACE_MAP[base_w] or base_w
    return (nh * nw * l) / 12
end

return Normalize
