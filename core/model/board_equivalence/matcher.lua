-- core/model/board_equivalence/matcher.lua
--
-- Board equivalence matcher.
--
-- Determines best candidate board given an order board
-- and a candidate set.
--
-- Priority tiers:
--   exact → dim+grade → family → nearest
--
-- Signal encoding:
--   H = height equal
--   W = width equal
--   L = length equal
--   G = grade equal
--   T = tag equal
--
-- Grade delta suffix:
--   = + - ?

local Schema = require("core.schema").schema
local BoardEquivalence = {}

local function build_grade_cache()

    local map = {}

    local values = Schema.values("board.grade") or {}

    for _,rec in ipairs(values) do
        map[rec.name] = rec.value or 0
    end

    return map
end

local GRADE_VALUE = build_grade_cache()

----------------------------------------------------------------
-- Grade delta
----------------------------------------------------------------

local function grade_delta(a, b)

    local ga = a and a.grade
    local gb = b and b.grade

    if not ga or not gb then
        return "?"
    end

    local va = GRADE_VALUE[ga]
    local vb = GRADE_VALUE[gb]

    if not va or not vb then
        return "?"
    end

    local EPS = 0.01

    if math.abs(vb - va) <= EPS then
        return "="
    end

    if vb > va then
        return "+"
    end

    return "-"
end

----------------------------------------------------------------
-- Match signal
----------------------------------------------------------------

-- core/model/board_equivalence/matcher.lua
-- function: signal

local function signal(a, b)
    if not a or not b then
        return "?"
    end

    local sig = {}

    ------------------------------------------------------------
    -- Dimension matches (only if both values exist)
    ------------------------------------------------------------

    if a.h and b.h and a.h == b.h then
        sig[#sig + 1] = "H"
    end

    if a.w and b.w and a.w == b.w then
        sig[#sig + 1] = "W"
    end

    if a.l and b.l and a.l == b.l then
        sig[#sig + 1] = "L"
    end

    ------------------------------------------------------------
    -- Tag match (only if both tags exist)
    ------------------------------------------------------------

    if a.tag and b.tag and a.tag == b.tag then
        sig[#sig + 1] = "T"
    end

    ------------------------------------------------------------
    -- Grade match (only if both grades exist)
    ------------------------------------------------------------

    if a.grade and b.grade and a.grade == b.grade then
        sig[#sig + 1] = "G"
    end

    ------------------------------------------------------------
    -- Grade delta always appended
    ------------------------------------------------------------

    sig[#sig + 1] = grade_delta(a, b)

    return table.concat(sig)
end

----------------------------------------------------------------
-- Tier rules
----------------------------------------------------------------

local function exact(a, b)
    return a and b
        and a.h == b.h
        and a.w == b.w
        and a.l == b.l
        and (a.grade or "") == (b.grade or "")
        and (a.tag or "") == (b.tag or "")
end

local function dim_grade(a, b)
    return a and b
        and a.h == b.h
        and a.w == b.w
        and (a.grade or "") == (b.grade or "")
        and (a.tag or "") == (b.tag or "")
end

local function family(a, b)
    return a and b
        and a.h == b.h
        and a.w == b.w
        and (a.tag or "") == (b.tag or "")
end

local function nearest(a, list)
    if not a then
        return nil
    end

    local best
    local best_d

    for _, b in ipairs(list or {}) do
        local d =
            math.abs((a.h or 0) - (b.h or 0)) +
            math.abs((a.w or 0) - (b.w or 0))

        if not best_d or d < best_d then
            best = b
            best_d = d
        end
    end

    return best
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

-- core/model/board_equivalence/matcher.lua
-- function: BoardEquivalence.match

function BoardEquivalence.match(order_board, candidates)

    if not order_board then
        return nil, "none"
    end

    local best
    local best_tier
    local best_distance

    for _, b in ipairs(candidates or {}) do

        local tier

        ------------------------------------------------------------
        -- Determine tier
        ------------------------------------------------------------

        if exact(order_board, b) then
            tier = 1

        elseif dim_grade(order_board, b) then
            tier = 2

        elseif family(order_board, b) then
            tier = 3

        else
            tier = 4
        end

        ------------------------------------------------------------
        -- Compute distance (for tie-breaking)
        ------------------------------------------------------------

        local distance =
            math.abs((order_board.h or 0) - (b.h or 0)) +
            math.abs((order_board.w or 0) - (b.w or 0))

        ------------------------------------------------------------
        -- Select best candidate
        ------------------------------------------------------------

        if not best then
            best = b
            best_tier = tier
            best_distance = distance

        elseif tier < best_tier then
            best = b
            best_tier = tier
            best_distance = distance

        elseif tier == best_tier and distance < best_distance then
            best = b
            best_distance = distance
        end
    end

    ------------------------------------------------------------
    -- No candidates
    ------------------------------------------------------------

    if not best then
        return nil, "none"
    end

    return best, signal(order_board, best)
end

return BoardEquivalence
