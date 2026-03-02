-- system/app/fs.lua
--
-- Filesystem capability root.
-- Provides:
--   • store() → canonical, domain-significant locations (AppFSResult)
--   • util()  → lifecycle + introspection helpers (tables / structured metadata + helpers)

local Storage      = require("system.infrastructure.storage.controller")
local AppFS        = require("system.infrastructure.app_fs.controller")
local Registry     = require("system.infrastructure.app_fs.registry")
local HelpersFacade= require("system.app.fs_helpers")

----------------------------------------------------------------
-- Store Namespace
----------------------------------------------------------------

---@class AppFSStore
local Store = {}
Store.__index = Store

---@return AppFSStore
function Store.new()
    return setmetatable({}, Store)
end

------------------------------------------------------------
-- store(): domain roots
------------------------------------------------------------

---@return AppFSResult
function Store:ledger() return AppFS.ledger() end

---@return AppFSResult
function Store:client() return AppFS.client() end

---@return AppFSResult
function Store:vendor() return AppFS.vendor() end

------------------------------------------------------------
-- store(): user roots
------------------------------------------------------------

---@return AppFSResult
function Store:user() return AppFS.user() end

---@return AppFSResult
function Store:imports() return AppFS.user_imports() end

---@return AppFSResult
function Store:exports() return AppFS.user_exports() end

---@return AppFSResult
function Store:vault() return AppFS.user_vault() end

------------------------------------------------------------
-- store(): system roots
------------------------------------------------------------

---@return AppFSResult
function Store:system() return AppFS.system() end

---@return AppFSResult
function Store:staged() return AppFS.system_staged() end

---@return AppFSResult
function Store:sessions() return AppFS.system_sessions() end

---@return AppFSResult
function Store:runtime_ids() return AppFS.system_runtime_ids() end

---@return AppFSResult
function Store:presets() return AppFS.system_presets() end

---@return AppFSResult
function Store:last_session() return AppFS.last_session() end

---Return presets subdirectory for a given domain (string param).
---Example: fs():store():preset_domain("ledger"):files()
---@param domain string
---@return AppFSResult
function Store:preset_domain(domain)
    assert(type(domain) == "string" and #domain > 0, "[fs.store] domain required")
    local root = AppFS.system_presets():path()
    local path = HelpersFacade.new():join(root, domain)
    local Result = require("system.infrastructure.app_fs.result")
    return Result.new(path)
end

----------------------------------------------------------------
-- Util Namespace
----------------------------------------------------------------

---@class AppFSUtil
---@field private _helpers AppFSHelpers|nil
local Util = {}
Util.__index = Util

---@return AppFSUtil
function Util.new()
    return setmetatable({ _helpers = nil }, Util)
end

---Ensure canonical directory layout exists (creates missing dirs).
---@return boolean
function Util:ensure_layout()
    return AppFS.ensure_instance_layout()
end

---Return Registry.locations (logical schema map, no IO).
---@return table
function Util:inspect_schema()
    return Registry.locations
end

---Return resolved filesystem graph (IO ok).
---@return table
function Util:inspect_graph()
    return AppFS.inspect_fs()
end

---Return Storage.app_root() (absolute path string).
---@return string
function Util:app_root()
    return Storage.app_root()
end

---Return app fs root directory (./data/app) absolute.
---@return string
function Util:fs_root()
    local project_root = Storage.project_root()
    return (project_root:gsub("\\", "/"):gsub("/$", "")) .. "/data/app"
end

---Return app-level filesystem helpers (join/child/ext/stem/exists).
---@return AppFSHelpers
function Util:helpers()
    if not self._helpers then
        self._helpers = HelpersFacade.new()
    end
    return self._helpers
end

----------------------------------------------------------------
-- FS Facade Root
----------------------------------------------------------------

---@class AppFSFacade
---@field private _store AppFSStore|nil
---@field private _util AppFSUtil|nil
local FS = {}
FS.__index = FS

---@return AppFSFacade
function FS.new()
    return setmetatable({
        _store = nil,
        _util  = nil,
    }, FS)
end

---Return canonical store namespace.
---@return AppFSStore
function FS:store()
    if not self._store then
        self._store = Store.new()
    end
    return self._store
end

---Return dev/lifecycle namespace.
---@return AppFSUtil
function FS:util()
    if not self._util then
        self._util = Util.new()
    end
    return self._util
end

return FS
