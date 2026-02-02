-- presentation/exports/compare/matcher.lua
--
-- Best-effort board alignment.
-- No pricing. No rendering.

local BoardMatcher = {}

local function dist(a, b)
    return math.abs(a.h - b.h) + math.abs(a.w - b.w)
end

local function exact(a, b)
    return a.h == b.h and a.w == b.w and a.l == b.l
       and (a.grade or "") == (b.grade or "")
       and (a.tag   or "") == (b.tag   or "")
end

local function family(a, b)
    return a.h == b.h and a.w == b.w
       and (a.tag or "") == (b.tag or "")
end

function BoardMatcher.match(order_board, candidates)
    local nearest, nearest_dist

    for _, c in ipairs(candidates) do
        if exact(order_board, c) then
            return c, "exact"
        end

        if family(order_board, c) then
            return c, "family"
        end

        local d = dist(order_board, c)
        if not nearest_dist or d < nearest_dist then
            nearest, nearest_dist = c, d
        end
    end

    if nearest then
        return nearest, "nearest"
    end

    return nil, "none"
end

return BoardMatcher
