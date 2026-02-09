-- interface/shells/tui/widgets/state.lua
--
-- Transient TUI state container.
-- No persistence. No business logic.

local State = {}
State.__index = State

function State.new()
    return setmetatable({
        cursor     = nil,
        selections = {},
    }, State)
end

return State
