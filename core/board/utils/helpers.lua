local Util = {}

function Util.round_number(value, decimal_places)
    decimal_places = decimal_places or 0

    local multiplier = 10 ^ decimal_places

    if value >= 0 then
        return math.floor(value * multiplier + 0.5) / multiplier
    else
        -- correct symmetric behavior for negatives
        return math.ceil(value * multiplier - 0.5) / multiplier
    end
end

function Util.check_board_attrs(board, ...)
    assert(type(board) == "table", "check_board_attrs(): board must be a table")

    local caller = debug.getinfo(2, "n")
    local caller_name = caller and caller.name or "<anonymous>"

    local required_attrs = { ... }

    for i = 1, #required_attrs do
        local attr = required_attrs[i]
        local value = board[attr]

        if value == nil then
            error(string.format("%s(): missing required board attribute '%s'", caller_name, attr), 2)
        end

        -- basic numeric sanity check (opt-in by usage)
        if type(value) == "number" and value < 0 then
            error(string.format("%s(): board.%s must be non-negative", caller_name, attr), 2)
        end
    end
end

return Util
