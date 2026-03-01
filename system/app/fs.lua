-- system/app/fs.lua

local AppFS = require("system.infrastructure.app_fs.controller")

---@class AppFSFacade
local FS = {}
FS.__index = FS

function FS.new()
    return setmetatable({}, FS)
end

------------------------------------------------------------
-- Store Access (Primary Surface)
------------------------------------------------------------

---@return table
function FS:store()
    return {
        vendor = function() return AppFS.vendor_store() end,
        ledger = function() return AppFS.ledger_store() end,
        sessions = function() return AppFS.sessions() end,
        exports = function() return AppFS.exports() end,
        clients = function() return AppFS.clients() end,
        user_inputs = function() return AppFS.user_inputs() end,
        user_exports = function() return AppFS.user_exports() end,
        runtime_ids = function() return AppFS.runtime_ids() end,
    }
end

------------------------------------------------------------
-- Inspection Surface
------------------------------------------------------------

---@return table
function FS:inspect()
    return {
        schema = function() return AppFS.inspect_schema() end,
        fs = function() return AppFS.inspect_fs() end,
    }
end

------------------------------------------------------------
-- Raw Infrastructure Access
------------------------------------------------------------

---@return table
function FS:raw()
    return {
        get = function(name) return AppFS.get(name) end,
        get_raw = function(name) return AppFS.get_raw(name) end,
        get_strict = function(name) return AppFS.get_strict(name) end,
        ensure_layout = function() return AppFS.ensure_instance_layout() end,
    }
end

return FS
