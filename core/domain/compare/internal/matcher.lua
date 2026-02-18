-- core/domain/compare/internal/matcher.lua
--
-- Priority matcher on canonical runtime board envelope (flat fields):
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
--   = + - ?  (value-based)

local Grade = require("core.enums.grades")

local BoardMatcher = {}

----------------------------------------------------------------
-- Grade delta (value-based)
----------------------------------------------------------------

local function grade_delta(order_board, vendor_board)
    local order_grade  = order_board and order_board.grade
    local vendor_grade = vendor_board and vendor_board.grade

    if not order_grade or not vendor_grade then
        return "?"
    end

    local A = Grade.get(order_grade)
    local B = Grade.get(vendor_grade)

    if not A or not B or A.kind ~= "grade" or B.kind ~= "grade" then
        return "?"
    end

    local va = A.value or 0
    local vb = B.value or 0

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
    if not a or not b then
        return "?"
    end

    local sig = {}

    if a.h == b.h then sig[#sig + 1] = "H" end
    if a.w == b.w then sig[#sig + 1] = "W" end
    if a.l == b.l then sig[#sig + 1] = "L" end
    if (a.tag   or "") == (b.tag   or "") then sig[#sig + 1] = "T" end
    if (a.grade or "") == (b.grade or "") then sig[#sig + 1] = "G" end

    sig[#sig + 1] = grade_delta(a, b)

    return table.concat(sig)
end

----------------------------------------------------------------
-- Match tiers
----------------------------------------------------------------

local function exact(a, b)
    return a and b
       and a.h == b.h
       and a.w == b.w
       and a.l == b.l
       and (a.grade or "") == (b.grade or "")
       and (a.tag   or "") == (b.tag   or "")
end

local function dim_grade(a, b)
    return a and b
       and a.h == b.h
       and a.w == b.w
       and (a.grade or "") == (b.grade or "")
       and (a.tag   or "") == (b.tag   or "")
end

local function family(a, b)
    return a and b
       and a.h == b.h
       and a.w == b.w
       and (a.tag or "") == (b.tag or "")
end

local function nearest(a, list)
    if not a then return nil end

    local best, best_d

    for _, b in ipairs(list or {}) do
        if b then
            local d =
                math.abs((a.h or 0) - (b.h or 0)) +
                math.abs((a.w or 0) - (b.w or 0))

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
    for _, b in ipairs(candidates or {}) do
        if exact(order_board, b) then
            return b, match_signal(order_board, b)
        end
    end

    for _, b in ipairs(candidates or {}) do
        if dim_grade(order_board, b) then
            return b, match_signal(order_board, b)
        end
    end

    for _, b in ipairs(candidates or {}) do
        if family(order_board, b) then
            return b, match_signal(order_board, b)
        end
    end

    local n = nearest(order_board, candidates or {})
    if n then
        return n, match_signal(order_board, n)
    end

    return nil, "none"
end

return BoardMatcher
