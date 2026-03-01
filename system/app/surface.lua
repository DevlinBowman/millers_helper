-- system/app/surface.lua
--
-- Surface: application boundary object.
-- Owns instance selection and exposes application capabilities.
--
-- Top-level capabilities:
--   • fs()        → filesystem capability
--   • data()      → state/data capability
--   • services()  → orchestration services capability
--
-- Surface must NOT expose infrastructure modules directly.

local Storage  = require("system.infrastructure.storage.controller")
local AppFS    = require("system.infrastructure.app_fs.controller")
local Registry = require("system.infrastructure.app_fs.registry")

local FSFacade       = require("system.app.fs")
local DataFacade     = require("system.app.data")
local ServicesFacade = require("system.app.services")

---@class Surface
---@field private _instance string
---@field private _fs AppFSFacade|nil
---@field private _data AppDataFacade|nil
---@field private _services AppServicesFacade|nil
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

    -- Set active instance in storage layer
    Storage.set_instance(instance_name)

    -- Ensure canonical directory layout exists
    AppFS.ensure_instance_layout()

    return setmetatable({
        _instance = instance_name,
        _fs = nil,
        _data = nil,
        _services = nil,
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
-- State Inspect (Logical Only)
------------------------------------------------------------

---Return logical schema state (no filesystem access).
---@return table
function Surface:inspect_state()
    return {
        instance  = self._instance,
        app_root  = Storage.app_root(),
        locations = Registry.locations,
    }
end

------------------------------------------------------------
-- Graph Inspect (Filesystem Reality)
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
-- Capability: Filesystem
------------------------------------------------------------

---Return filesystem capability surface.
---@return AppFSFacade
function Surface:fs()
    if not self._fs then
        self._fs = FSFacade.new()
    end
    return self._fs
end

------------------------------------------------------------
-- Capability: Data / State
------------------------------------------------------------

---Return state/data capability surface.
---@return AppDataFacade
function Surface:data()
    if not self._data then
        self._data = DataFacade.new()
    end
    return self._data
end

------------------------------------------------------------
-- Capability: Services
------------------------------------------------------------

---Return services capability surface.
---@return AppServicesFacade
function Surface:services()
    if not self._services then
        self._services = ServicesFacade.new()
    end
    return self._services
end

return Surface
