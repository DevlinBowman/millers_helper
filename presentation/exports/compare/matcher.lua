-- presentation/exports/compare/matcher.lua
--
-- Priority matcher:
-- exact → dim+grade → family → nearest
--
-- Match signal encoding (derived ONLY from existing equality checks):
--   H = height
--   W = width
--   L = length
--   G = grade
--   T = tag

local BoardMatcher = {}

local function p(b) return b and b.physical end

----------------------------------------------------------------
-- Signal compiler (no new logic)
----------------------------------------------------------------

local function match_signal(a, b)
    local ap, bp = p(a), p(b)
    if not ap or not bp then return "" end

    local sig = {}

    if ap.h == bp.h then sig[#sig + 1] = "H" end
    if ap.w == bp.w then sig[#sig + 1] = "W" end
    if ap.l == bp.l then sig[#sig + 1] = "L" end
    if (ap.grade or "") == (bp.grade or "") then sig[#sig + 1] = "G" end
    if (ap.tag   or "") == (bp.tag   or "") then sig[#sig + 1] = "T" end

    return table.concat(sig)
end

----------------------------------------------------------------
-- Existing match tiers (unchanged)
----------------------------------------------------------------

local function exact(a, b)
    local ap, bp = p(a), p(b)
    return ap and bp
       and ap.h == bp.h and ap.w == bp.w and ap.l == bp.l
       and (ap.grade or "") == (bp.grade or "")
       and (ap.tag   or "") == (bp.tag   or "")
end

local function dim_grade(a, b)
    local ap, bp = p(a), p(b)
    return ap and bp
       and ap.h == bp.h and ap.w == bp.w
       and (ap.grade or "") == (bp.grade or "")
       and (ap.tag   or "") == (bp.tag   or "")
end

local function family(a, b)
    local ap, bp = p(a), p(b)
    return ap and bp
       and ap.h == bp.h and ap.w == bp.w
       and (ap.tag or "") == (bp.tag or "")
end

local function nearest(a, list)
    local ap = p(a)
    if not ap then return nil end

    local best, best_d
    for _, b in ipairs(list) do
        local bp = p(b)
        if bp then
            local d = math.abs(ap.h - bp.h) + math.abs(ap.w - bp.w)
            if not best_d or d < best_d then
                best, best_d = b, d
            end
        end
    end
    return best
end

----------------------------------------------------------------
-- Match entrypoint
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
