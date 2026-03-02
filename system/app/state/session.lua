-- system/app/data/session.lua

local Storage = require("system.infrastructure.storage.controller")

---@class AppDataSession
---@field private __state table
local Session = {}
Session.__index = Session

function Session.new(state)
    return setmetatable({ __state = state }, Session)
end

function Session:snapshot()
    return self.__state
end

function Session:restore(snapshot)
    assert(type(snapshot) == "table", "[data.session] invalid snapshot")
    self.__state = snapshot
end

return Session
