-- core/board/utils.lua
--
-- Shared utility helpers for board-related operations.
-- Pure functions only. No side effects beyond errors.

local Util = {}

----------------------------------------------------------------
-- Numeric helpers
----------------------------------------------------------------

--- Round a number to a fixed number of decimal places.
--- Uses symmetric rounding for positive and negative values.
---
--- @param value number
--- @param decimal_places number|nil  -- default: 0
--- @return number
function Util.round_number(value, decimal_places)
    assert(type(value) == "number", "round_number(): value must be a number")

    decimal_places = decimal_places or 0
    assert(type(decimal_places) == "number" and decimal_places >= 0,
        "round_number(): decimal_places must be a non-negative number")

    local factor = 10 ^ decimal_places

    if value >= 0 then
        return math.floor(value * factor + 0.5) / factor
    end

    -- symmetric rounding for negatives
    return math.ceil(value * factor - 0.5) / factor
end

----------------------------------------------------------------
-- Board contract helpers
----------------------------------------------------------------

--- Assert that a board table contains required attributes.
--- Optionally enforces non-negative numeric values.
---
--- Intended for internal invariant enforcement, not user validation.
---
--- @param board table
--- @param ... string  -- required attribute names
function Util.check_board_attrs(board, ...)
    assert(type(board) == "table", "check_board_attrs(): board must be a table")

    local caller_info = debug.getinfo(2, "n")
    local caller_name = (caller_info and caller_info.name) or "<anonymous>"

    local required_attrs = { ... }

    for i = 1, #required_attrs do
        local field = required_attrs[i]
        local value = board[field]

        if value == nil then
            error(
                string.format(
                    "%s(): missing required board field '%s'",
                    caller_name,
                    field
                ),
                2
            )
        end

        -- Numeric sanity check (only applies if the value is numeric)
        if type(value) == "number" and value < 0 then
            error(
                string.format(
                    "%s(): board.%s must be non-negative",
                    caller_name,
                    field
                ),
                2
            )
        end
    end
end

return Util
