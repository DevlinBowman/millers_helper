-- system/app/state/session.lua

local Storage = require("system.infrastructure.storage.controller")

---@class AppDataSession
---@field private __vars table
local Session = {}
Session.__index = Session

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param vars_state table
---@return AppDataSession
function Session.new(vars_state)

    assert(type(vars_state) == "table", "[data.session] vars_state required")

    return setmetatable({
        __vars = vars_state
    }, Session)
end

------------------------------------------------------------
-- Snapshot
------------------------------------------------------------

function Session:snapshot()
    return self.__vars
end

------------------------------------------------------------
-- Restore
------------------------------------------------------------

function Session:restore(snapshot)

    assert(type(snapshot) == "table", "[data.session] invalid snapshot")

    self.__vars = snapshot
end

return Session
