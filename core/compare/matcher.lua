-- core/compare/matcher.lua
--
-- Priority matcher:
--   exact → dim+grade → family → nearest
--
-- Match signal encoding:
--   H = height equal
--   W = width equal
--   L = length equal
--   G = grade equal
--   T = tag equal
--
-- Grade delta suffix (always appended):
--   =  vendor grade ~= order grade
--   +  vendor grade better than order
--   -  vendor grade worse than order
--   ?  grade unknown / unresolved
--
-- IMPORTANT:
--   • Grade delta is VALUE-based (market pressure), not rank-based
--   • No pricing adjustment is performed here

local Grade = require("core.enums.grades")

local BoardMatcher = {}

local function p(b)
    return b and b.physical
end

----------------------------------------------------------------
-- Grade delta (value-based)
----------------------------------------------------------------

local function grade_delta(order_board, vendor_board)
    local og = order_board
        and order_board.physical
        and order_board.physical.grade

    local vg = vendor_board
        and vendor_board.physical
        and vendor_board.physical.grade

    if not og or not vg then
        return "?"
    end

    local A = Grade.get(og)
    local B = Grade.get(vg)

    if not A or not B or A.kind ~= "grade" or B.kind ~= "grade" then
        return "?"
    end

    local va = A.value or 0
    local vb = B.value or 0

    -- tolerance to avoid floating noise
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
-- Match signal compiler
----------------------------------------------------------------

local function match_signal(a, b)
    local ap, bp = p(a), p(b)
    if not ap or not bp then
        return "?"
    end

    local sig = {}

    if ap.h == bp.h then sig[#sig + 1] = "H" end
    if ap.w == bp.w then sig[#sig + 1] = "W" end
    if ap.l == bp.l then sig[#sig + 1] = "L" end
    if (ap.tag   or "") == (bp.tag   or "") then sig[#sig + 1] = "T" end
    if (ap.grade or "") == (bp.grade or "") then sig[#sig + 1] = "G" end

    -- append grade delta suffix (always present)
    sig[#sig + 1] = grade_delta(a, b)

    return table.concat(sig)
end

----------------------------------------------------------------
-- Match tiers (unchanged semantics)
----------------------------------------------------------------

local function exact(a, b)
    local ap, bp = p(a), p(b)
    return ap and bp
       and ap.h == bp.h
       and ap.w == bp.w
       and ap.l == bp.l
       and (ap.grade or "") == (bp.grade or "")
       and (ap.tag   or "") == (bp.tag   or "")
end

local function dim_grade(a, b)
    local ap, bp = p(a), p(b)
    return ap and bp
       and ap.h == bp.h
       and ap.w == bp.w
       and (ap.grade or "") == (bp.grade or "")
       and (ap.tag   or "") == (bp.tag   or "")
end

local function family(a, b)
    local ap, bp = p(a), p(b)
    return ap and bp
       and ap.h == bp.h
       and ap.w == bp.w
       and (ap.tag or "") == (bp.tag or "")
end

local function nearest(a, list)
    local ap = p(a)
    if not ap then return nil end

    local best, best_d

    for _, b in ipairs(list) do
        local bp = p(b)
        if bp then
            local d =
                math.abs(ap.h - bp.h) +
                math.abs(ap.w - bp.w)

            if not best_d or d < best_d then
                best, best_d = b, d
            end
        end
    end

    return best
end

----------------------------------------------------------------
-- Public entrypoint
----------------------------------------------------------------

function BoardMatcher.match(order_board, candidates)
    for _, b in ipairs(candidates) do
        if exact(order_board, b) then
            return b, match_signal(order_board, b)
        end
    end

    for _, b in ipairs(candidates) do
        if dim_grade(order_board, b) then
            return b, match_signal(order_board, b)
        end
    end

    for _, b in ipairs(candidates) do
        if family(order_board, b) then
            return b, match_signal(order_board, b)
        end
    end

    local n = nearest(order_board, candidates)
    if n then
        return n, match_signal(order_board, n)
    end

    return nil, "none"
end

return BoardMatcher
