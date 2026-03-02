-- system/infrastructure/app_fs/controller.lua
--
-- AppFS Infrastructure Controller
--
-- Responsibilities:
--   • Resolve canonical filesystem locations from the registry
--   • Ensure instance directory layout exists
--   • Provide AppFSResult façades for canonical locations
--   • Provide schema + filesystem reality inspection
--
-- Notes:
--   • This is infrastructure (not a capability façade).
--   • Callers should typically go through app:fs():store() / app:fs():util()
--     instead of requiring this module directly.

local Storage  = require("system.infrastructure.storage.controller")
local Registry = require("system.infrastructure.app_fs.registry")
local Result   = require("system.infrastructure.app_fs.result")

---@class AppFS
local AppFS = {}

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

---@param path string|nil
---@return string
local function normalize_path(path)
    return (path or ""):gsub("\\", "/")
end

---@param a string
---@param b string
---@return string
local function join2(a, b)
    a = normalize_path(a or "")
    b = normalize_path(b or "")
    if a:sub(-1) == "/" then a = a:sub(1, -2) end
    if b:sub(1, 1) == "/" then b = b:sub(2) end
    return a .. "/" .. b
end

---@param name string
---@return table|nil, string|nil
local function resolve_location(name)
    local relative = Registry.locations[name]
    if not relative then
        return nil, "[app_fs] unknown location: " .. tostring(name)
    end

    local absolute = join2(Storage.app_root(), relative)

    return {
        name     = name,
        relative = relative,
        absolute = absolute,
    }
end

------------------------------------------------------------
-- Layout
------------------------------------------------------------

---Ensure canonical directory structure exists for the active instance.
---@return boolean
function AppFS.ensure_instance_layout()
    local root = Storage.app_root()
    Storage.ensure_dir(root)

    for _, rel in ipairs(Registry.ensure_dirs) do
        Storage.ensure_dir(join2(root, rel))
    end

    return true
end

------------------------------------------------------------
-- Raw (DTO)
------------------------------------------------------------

---Return raw location DTO for a canonical registry name.
---@param name string
---@return table|nil, string|nil
function AppFS.get_raw(name)
    return resolve_location(name)
end

------------------------------------------------------------
-- Façade
------------------------------------------------------------

---Return AppFSResult façade for a canonical registry name.
---@param name string
---@return AppFSResult|nil, string|nil
function AppFS.get(name)
    local dto, err = AppFS.get_raw(name)
    if not dto then
        return nil, err
    end
    return Result.new(dto.absolute)
end

---Return AppFSResult façade or throw.
---@param name string
---@return AppFSResult
function AppFS.get_strict(name)
    local res, err = AppFS.get(name)
    if not res then
        error(err, 2)
    end
    return res
end

------------------------------------------------------------
-- Named Accessors (New Standard)
-- These MUST correspond to keys in system/infrastructure/app_fs/registry.lua
------------------------------------------------------------

------------------------------------------------------------
-- Domain roots
------------------------------------------------------------

---Ledger domain root.
---@return AppFSResult
function AppFS.ledger()
    return AppFS.get_strict("ledger")
end

---Client domain root.
---@return AppFSResult
function AppFS.client()
    return AppFS.get_strict("client")
end

---Vendor cache root.
---@return AppFSResult
function AppFS.vendor()
    return AppFS.get_strict("vendor")
end

------------------------------------------------------------
-- User roots (persisted, user-facing)
------------------------------------------------------------

---User root directory.
---@return AppFSResult
function AppFS.user()
    return AppFS.get_strict("user")
end

---User imports directory (persisted by policy).
---@return AppFSResult
function AppFS.user_imports()
    return AppFS.get_strict("user_imports")
end

---User exports directory.
---@return AppFSResult
function AppFS.user_exports()
    return AppFS.get_strict("user_exports")
end

---User vault directory (curated saved inputs).
---@return AppFSResult
function AppFS.user_vault()
    return AppFS.get_strict("user_vault")
end

------------------------------------------------------------
-- System roots (system-owned)
------------------------------------------------------------

---System root directory.
---@return AppFSResult
function AppFS.system()
    return AppFS.get_strict("system")
end

---System staged directory (ephemeral runtime staging).
---@return AppFSResult
function AppFS.system_staged()
    return AppFS.get_strict("system_staged")
end

---System sessions directory (state snapshots).
---@return AppFSResult
function AppFS.system_sessions()
    return AppFS.get_strict("system_sessions")
end

---System runtime_ids directory (counters).
---@return AppFSResult
function AppFS.system_runtime_ids()
    return AppFS.get_strict("system_runtime_ids")
end

---System presets directory (domain presets).
---@return AppFSResult
function AppFS.system_presets()
    return AppFS.get_strict("system_presets")
end

------------------------------------------------------------
-- System files
------------------------------------------------------------

---Last session snapshot file.
---@return AppFSResult
function AppFS.last_session()
    return AppFS.get_strict("last_session")
end

------------------------------------------------------------
-- Inspect
------------------------------------------------------------

---Return static schema map (Registry.locations).
---@return table
function AppFS.inspect_schema()
    return Registry.locations
end

---Return filesystem reality map keyed by registry name.
---Each entry contains: relative, absolute, exists, kind.
---@return table<string, table>
function AppFS.inspect_fs()
    local out = {}

    for name, relative in pairs(Registry.locations) do
        local dto = resolve_location(name)
        local res = Result.new(dto.absolute)

        local exists = false
        local kind = "missing"

        local ok, query = pcall(function()
            return res:query()
        end)

        if ok and query then
            exists = query:exists()
            if query:is_directory() then
                kind = "directory"
            elseif query:is_file() then
                kind = "file"
            else
                kind = "missing"
            end
        end

        out[name] = {
            relative = relative,
            absolute = dto.absolute,
            exists   = exists,
            kind     = kind,
        }
    end

    return out
end

return AppFS
