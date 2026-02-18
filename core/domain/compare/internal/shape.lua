-- core/domain/compare/internal/shape.lua
--
-- Structural validation for canonical runtime board envelope.
-- No mutation. No normalization.
-- Geometry only. Pricing is optional.

local Shape = {}

local function is_table(v)
    return type(v) == "table"
end

local function assertf(cond, msg)
    if not cond then
        return false, msg
    end
    return true
end

----------------------------------------------------------------
-- Board validation (canonical runtime shape)
----------------------------------------------------------------

local function validate_board(b, ctx)
    local ok, err

    ok, err = assertf(is_table(b), ctx .. " must be table")
    if not ok then return false, err end

    ok, err = assertf(type(b.h) == "number", ctx .. ".h required (number)")
    if not ok then return false, err end

    ok, err = assertf(type(b.w) == "number", ctx .. ".w required (number)")
    if not ok then return false, err end

    ok, err = assertf(type(b.l) == "number", ctx .. ".l required (number)")
    if not ok then return false, err end

    return true
end

----------------------------------------------------------------
-- Input validation
----------------------------------------------------------------

function Shape.validate_input(input)
    if not is_table(input) then
        return false, "input must be table"
    end

    if not is_table(input.order)
    or not is_table(input.order.boards) then
        return false, "input.order.boards required"
    end

    for i, b in ipairs(input.order.boards) do
        local ok, err = validate_board(b, "order.boards[" .. i .. "]")
        if not ok then return false, err end
    end

    if not is_table(input.sources) then
        return false, "input.sources required"
    end

    for si, src in ipairs(input.sources) do
        if type(src.name) ~= "string" then
            return false, "sources[" .. si .. "].name required"
        end

        for bi, b in ipairs(src.boards or {}) do
            local ok, err = validate_board(
                b,
                src.name .. ".boards[" .. bi .. "]"
            )
            if not ok then return false, err end
        end
    end

    return true
end

----------------------------------------------------------------
-- Model validation
----------------------------------------------------------------

function Shape.validate_model(model)
    if not is_table(model) then
        return false, "model must be table"
    end

    if not is_table(model.rows) then
        return false, "model.rows required"
    end

    if not is_table(model.totals) then
        return false, "model.totals required"
    end

    return true
end

return Shape
