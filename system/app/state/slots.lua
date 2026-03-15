-- system/app/state/slots.lua

---@class AppDataSlots
---@field private __slots table
local Slots = {}
Slots.__index = Slots

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param slots_state table
---@return AppDataSlots
function Slots.new(slots_state)

    assert(type(slots_state) == "table", "[slots] slots_state required")

    slots_state.selection = slots_state.selection or {
        user   = {},
        system = {},
    }

    slots_state.config = slots_state.config or {}

    return setmetatable({
        __slots = slots_state
    }, Slots)
end

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

local function normalize_selection(value)

    if value == nil then
        return {}
    end

    if type(value) == "number" then
        return {
            batch = value
        }
    end

    if type(value) == "string" then
        return {
            resource = value
        }
    end

    if type(value) == "table" then
        return {
            resource = value.resource or value.id,
            batch    = value.batch,
            board    = value.board
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

    self.__slots.selection[scope][role] =
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
        self.__slots.selection[scope][role]

    if value == nil then
        return nil
    end

    return normalize_selection(value)
end

------------------------------------------------------------
-- Clear Selection
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
function Slots:clear_selection(scope, role)

    self.__slots.selection[scope][role] =
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

    self.__slots.config[key] = value
end

---@param key string
---@return any
function Slots:get_config(key)
    return self.__slots.config[key]
end

------------------------------------------------------------
-- Resolver
------------------------------------------------------------

function Slots:resolve(scope, role)

    local sel =
        self:get_selection(scope, role)

    if not sel then
        return {}
    end

    return {
        resource = sel.resource,
        batch    = sel.batch,
        board    = sel.board
    }
end

return Slots
