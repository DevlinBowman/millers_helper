-- system/execution/capabilities.lua

local Capabilities = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function is_positive_number(value)
    return type(value) == "number" and value > 0
end

local function board_pricing_ready(board)
    if type(board) ~= "table" then
        return false
    end

    -- execution readiness should be cheap and explicit.
    -- bf_price is the basis authority for the pricing system.
    return is_positive_number(board.bf_price)
end

------------------------------------------------------------
-- Batch Pricing Readiness
------------------------------------------------------------

function Capabilities.batch_pricing_ready(target)
    local boards = target and target.boards

    if type(boards) ~= "table" or #boards == 0 then
        return false
    end

    for _, board in ipairs(boards) do
        if not board_pricing_ready(board) then
            return false
        end
    end

    return true
end

return Capabilities
