-- parsers/board_data/internal/chunk/chunk_predicates.lua

local CP = {}

function CP.has_num()
    return function(c)
        return c.has_num
    end
end

function CP.has_infix()
    return function(c)
        return c.has_infix
    end
end

function CP.size(n)
    return function(c)
        return c.size == n
    end
end

function CP.multi()
    return function(c)
        return c.size > 1
    end
end

function CP.single()
    return function(c)
        return c.size == 1
    end
end

return CP
