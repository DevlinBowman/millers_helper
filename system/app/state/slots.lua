-- system/app/state/slots.lua

---@class AppDataSlots
---@field private __state table
local Slots = {}
Slots.__index = Slots

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param state table
---@return AppDataSlots
function Slots.new(state)

    state.slots = state.slots or {}

    state.slots.selection = state.slots.selection or {
        user   = {},
        system = {},
    }

    state.slots.config = state.slots.config or {}

    return setmetatable({
        __state = state
    }, Slots)
end

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

local function normalize_selection(value)

    if type(value) == "number" then
        return { batch = value }
    end

    if type(value) == "string" then
        return { id = value }
    end

    if type(value) == "table" then
        return {
            batch = value.batch,
            board = value.board,
            id    = value.id
        }
    end

    error("[slots] invalid selection value")
end

------------------------------------------------------------
-- Selection
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param value number|string|table
function Slots:set_selection(scope, role, value)

    assert(scope == "system" or scope == "user",
        "[slots] invalid scope")

    assert(type(role) == "string" and role ~= "",
        "[slots] role required")

    local selection =
        normalize_selection(value)

    self.__state.slots.selection[scope][role] =
        selection
end

------------------------------------------------------------
-- Board-level targeting helper
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param batch_index number
---@param board_index number
function Slots:select_board(scope, role, batch_index, board_index)

    assert(type(batch_index) == "number",
        "[slots] batch_index required")

    assert(type(board_index) == "number",
        "[slots] board_index required")

    self:set_selection(scope, role, {
        batch = batch_index,
        board = board_index
    })
end

------------------------------------------------------------
-- Get Selection
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@return table|nil
function Slots:get_selection(scope, role)

    local value =
        self.__state.slots.selection[scope][role]

    if value == nil then
        return nil
    end

    if type(value) == "number"
        or type(value) == "string"
    then
        return normalize_selection(value)
    end

    return value
end

------------------------------------------------------------
-- Clear Selection
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
function Slots:clear_selection(scope, role)

    self.__state.slots.selection[scope][role] =
        nil
end

------------------------------------------------------------
-- Config (simple key-value)
------------------------------------------------------------

---@param key string
---@param value any
function Slots:set_config(key, value)

    assert(type(key) == "string" and key ~= "",
        "[slots] config key required")

    self.__state.slots.config[key] = value
end

---@param key string
---@return any
function Slots:get_config(key)
    return self.__state.slots.config[key]
end

return Slots
