-- system/infrastructure/app_fs/controller.lua

local Storage  = require("system.infrastructure.storage.controller")
local Registry = require("system.infrastructure.app_fs.registry")
local Result   = require("system.infrastructure.app_fs.result")

---@class AppFS
local AppFS = {}

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

local function normalize_path(path)
    return (path or ""):gsub("\\", "/")
end

local function join2(a, b)
    a = normalize_path(a or "")
    b = normalize_path(b or "")
    if a:sub(-1) == "/" then a = a:sub(1, -2) end
    if b:sub(1, 1) == "/" then b = b:sub(2) end
    return a .. "/" .. b
end

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

---Ensure canonical directory structure exists.
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
-- Raw
------------------------------------------------------------

---Return raw location DTO.
---@param name string
---@return table|nil, string|nil
function AppFS.get_raw(name)
    return resolve_location(name)
end

------------------------------------------------------------
-- Façade
------------------------------------------------------------

---Return AppFSResult façade.
---@param name string
---@return AppFSResult|nil, string|nil
function AppFS.get(name)
    local dto, err = AppFS.get_raw(name)
    if not dto then
        return nil, err
    end
    return Result.new(dto.absolute)
end

---Return AppFSResult or error.
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
-- Named Accessors
------------------------------------------------------------

---@return AppFSResult
function AppFS.vendor_store() return AppFS.get_strict("vendor_store") end

---@return AppFSResult
function AppFS.ledger_store() return AppFS.get_strict("ledger_store") end

---@return AppFSResult
function AppFS.runtime_ids() return AppFS.get_strict("runtime_ids") end

---@return AppFSResult
function AppFS.ledgers() return AppFS.get_strict("ledgers") end

---@return AppFSResult
function AppFS.sessions() return AppFS.get_strict("sessions") end

---@return AppFSResult
function AppFS.last_session() return AppFS.get_strict("last_session") end

---@return AppFSResult
function AppFS.exports() return AppFS.get_strict("exports") end

---@return AppFSResult
function AppFS.clients() return AppFS.get_strict("clients") end

---@return AppFSResult
function AppFS.user_inputs() return AppFS.get_strict("user_inputs") end

---@return AppFSResult
function AppFS.user_exports() return AppFS.get_strict("user_exports") end

------------------------------------------------------------
-- Inspect
------------------------------------------------------------

---Return static schema map.
---@return table
function AppFS.inspect_schema()
    return Registry.locations
end

---Return filesystem reality map.
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
