local Schema = require("core.schema")

local Capabilities = {}

local PRICE_FIELDS = {
    "bf_price",
    "ea_price",
    "lf_price",
}

------------------------------------------------------------
-- board pricing readiness
------------------------------------------------------------

local function board_pricing_ready(board)

    if type(board) ~= "table" then
        return false
    end

    local missing =
        Schema.object.missing("board", board)

    local missing_set = {}

    for _, name in ipairs(missing or {}) do
        missing_set[name] = true
    end

    for _, field in ipairs(PRICE_FIELDS) do
        if missing_set[field] then
            return false
        end
    end

    -- only basis for pricing system (all other prices are derived from this elsewhere)
    if type(board.bf_price) ~= "number" or board.bf_price <= 0 then
        return false
    end

    return true
end

------------------------------------------------------------
-- batch pricing readiness
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
