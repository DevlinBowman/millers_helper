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

local function signal(a, b)
    if not a or not b then
        return "?"
    end

    local sig = {}

    if a.h == b.h then sig[#sig + 1] = "H" end
    if a.w == b.w then sig[#sig + 1] = "W" end
    if a.l == b.l then sig[#sig + 1] = "L" end

    if (a.tag or "") == (b.tag or "") then
        sig[#sig + 1] = "T"
    end

    if (a.grade or "") == (b.grade or "") then
        sig[#sig + 1] = "G"
    end

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

function BoardEquivalence.match(order_board, candidates)
    for _, b in ipairs(candidates or {}) do
        if exact(order_board, b) then
            return b, signal(order_board, b)
        end
    end

    for _, b in ipairs(candidates or {}) do
        if dim_grade(order_board, b) then
            return b, signal(order_board, b)
        end
    end

    for _, b in ipairs(candidates or {}) do
        if family(order_board, b) then
            return b, signal(order_board, b)
        end
    end

    local n = nearest(order_board, candidates)

    if n then
        return n, signal(order_board, n)
    end

    return nil, "none"
end

return BoardEquivalence
