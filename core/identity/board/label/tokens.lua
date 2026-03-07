local Schema = require("core.identity.schema")

local Tokens = {}

local function num(n)
    return string.format("%.15g", n)
end

------------------------------------------------
-- dimension (declared)
------------------------------------------------

function Tokens.dimension(board)

    local tag = board.tag or Schema.default("board", "tag")

    return string.format(
        "%sx%sx%s%s",
        num(board.base_h),
        num(board.base_w),
        num(board.l),
        tag or ""
    )
end

------------------------------------------------
-- delivered dimension
------------------------------------------------

function Tokens.dimension_delivered(board)

    return string.format(
        "%sx%sx%s",
        num(board.h),
        num(board.w),
        num(board.l)
    )
end

------------------------------------------------
-- count
------------------------------------------------

function Tokens.count(board)

    local ct = board.ct or Schema.default("board", "ct")

    return "x" .. tostring(ct)
end

return Tokens
