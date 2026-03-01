-- system/app/data.lua
--
-- Application-level state/data capability surface.
-- Owns runtime state and submission management (future).

---@class AppDataFacade
local Data = {}
Data.__index = Data

---@return AppDataFacade
function Data.new()
    return setmetatable({}, Data)
end

------------------------------------------------------------
-- State Access (stub)
------------------------------------------------------------

---Return current in-memory state table.
---@return table
function Data:state()
    error("[app.data] not implemented")
end

---Replace current state (future reducer entry).
---@param state table
function Data:set_state(state)
    error("[app.data] not implemented")
end

---Ingest user submission (future).
---@param submission table
function Data:ingest(submission)
    error("[app.data] not implemented")
end

return Data
