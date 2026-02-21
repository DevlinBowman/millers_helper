-- core/formula/kerf.lua
--
-- Pure kerf waste model
-- All outputs normalized to board feet

local Kerf = {}

----------------------------------------------------------------
-- Internal
----------------------------------------------------------------

local function compute_total_bf(height_in, width_in, length_ft)
    return (height_in * width_in * length_ft) / 12
end

local function compute_waste_ratio(height_in, width_in, kerf_in)
    local numerator   = kerf_in * (height_in + width_in) - (kerf_in * kerf_in)
    local denominator = height_in * width_in
    return numerator / denominator
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

-- board = { h, w, l }
-- kerf_in = inches
function Kerf.run(board, kerf_in)
    assert(board and board.h and board.w and board.l, "invalid board")
    assert(kerf_in and kerf_in >= 0, "invalid kerf")

    local total_bf    = compute_total_bf(board.h, board.w, board.l)
    local waste_ratio = compute_waste_ratio(board.h, board.w, kerf_in)

    return {
        waste_ratio    = waste_ratio,                 -- dimensionless
        -- waste_per_bf   = waste_ratio,                 -- bf lost per 1 bf
        waste_total_bf = waste_ratio * total_bf       -- total bf lost
    }
end

return Kerf
