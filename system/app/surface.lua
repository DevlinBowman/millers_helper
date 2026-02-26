-- system/app/surface.lua
--
-- Surface: application boundary object.
-- Owns instance selection and exposes canonical filesystem access.

local Storage = require("system.infrastructure.storage.controller")
local AppFS   = require("system.infrastructure.app_fs.controller")
local Registry = require("system.infrastructure.app_fs.registry")

---@class Surface
---@field private _instance string
local Surface = {}
Surface.__index = Surface

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---Create and initialize a Surface for a given instance.
---@param instance_name string|nil
---@return Surface
function Surface.new(instance_name)
    instance_name = instance_name or "default"
    Storage.set_instance(instance_name)
    AppFS.ensure_instance_layout()

    return setmetatable({
        _instance = instance_name,
    }, Surface)
end

------------------------------------------------------------
-- Introspection
------------------------------------------------------------

---Return active instance name.
---@return string
function Surface:instance()
    return self._instance
end

---Return absolute app root path.
---@return string
function Surface:app_root()
    return Storage.app_root()
end

------------------------------------------------------------
-- State Inspect
------------------------------------------------------------

---Return logical schema state (no filesystem access).
---@return table
function Surface:inspect_state()
    return {
        instance = self._instance,
        app_root = Storage.app_root(),
        locations = Registry.locations
    }
end

------------------------------------------------------------
-- Graph Inspect
------------------------------------------------------------

---Return merged schema + filesystem reality graph.
---@return table
function Surface:inspect_graph()
    local fs_map = AppFS.inspect_fs()
    local graph = {}

    for name, node in pairs(fs_map) do
        graph[name] = {
            path     = node.absolute,
            exists   = node.exists,
            kind     = node.kind,
            relative = node.relative,
        }
    end

    return {
        instance = self._instance,
        root     = Storage.app_root(),
        nodes    = graph,
    }
end

------------------------------------------------------------
-- Canonical filesystem access
------------------------------------------------------------

---Return AppFS infrastructure controller.
---@return AppFS
function Surface:fs()
    return AppFS
end

---Return vendor store location.
---@return AppFSResult
function Surface:vendor_store()
    return AppFS.vendor_store()
end

---Return ledger store location.
---@return AppFSResult
function Surface:ledger_store()
    return AppFS.ledger_store()
end

---Return runtime IDs location.
---@return AppFSResult
function Surface:runtime_ids()
    return AppFS.runtime_ids()
end

---Return ledgers directory location.
---@return AppFSResult
function Surface:ledgers()
    return AppFS.ledgers()
end

---Return sessions directory location.
---@return AppFSResult
function Surface:sessions()
    return AppFS.sessions()
end

---Return last session file location.
---@return AppFSResult
function Surface:last_session()
    return AppFS.last_session()
end

---Return exports directory location.
---@return AppFSResult
function Surface:exports()
    return AppFS.exports()
end

---Return clients directory location.
---@return AppFSResult
function Surface:clients()
    return AppFS.clients()
end

---Return user inputs directory location.
---@return AppFSResult
function Surface:user_inputs()
    return AppFS.user_inputs()
end

---Return user exports directory location.
---@return AppFSResult
function Surface:user_exports()
    return AppFS.user_exports()
end

return Surface
