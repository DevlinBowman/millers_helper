-- system/infrastructure/storage/controller.lua

local FS = require("platform.io.registry").fs

---@class Storage
local Storage = {}

local active_instance = "default"
local cached_project_root = nil

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

local function normalize_path(path)
    return (path or ""):gsub("\\", "/")
end

local function dirname(path)
    return path:match("(.+)/[^/]+$") or nil
end

local function detect_project_root_containing_data()
    local source = debug.getinfo(1, "S").source
    local file_path = normalize_path(source:sub(2))
    local dir = dirname(file_path)
    assert(dir, "[storage] failed to determine file directory")

    while dir do
        if FS.is_dir(dir .. "/data") then
            return dir
        end

        local parent = dirname(dir)
        if not parent or parent == dir then
            break
        end
        dir = parent
    end

    error("[storage] could not locate project root containing /data", 2)
end

local function project_root()
    if cached_project_root then
        return cached_project_root
    end
    cached_project_root = detect_project_root_containing_data()
    return cached_project_root
end

local function join2(a, b)
    a = normalize_path(a or "")
    b = normalize_path(b or "")
    if a:sub(-1) == "/" then
        a = a:sub(1, -2)
    end
    if b:sub(1, 1) == "/" then
        b = b:sub(2)
    end
    return a .. "/" .. b
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

---Set active instance name.
---@param instance_name string
function Storage.set_instance(instance_name)
    assert(type(instance_name) == "string" and #instance_name > 0, "[storage] instance_name required")
    active_instance = instance_name
end

---Return active instance name.
---@return string
function Storage.instance()
    return active_instance
end

---Return project root containing /data.
---@return string
function Storage.project_root()
    return project_root()
end

---Return canonical app root path.
---@return string
function Storage.app_root()
    return join2(join2(project_root(), "data/app"), active_instance)
end

---Ensure directory exists.
---@param dir_path string
function Storage.ensure_dir(dir_path)
    assert(type(dir_path) == "string" and #dir_path > 0, "[storage] dir_path required")
    FS.ensure_parent_dir(normalize_path(dir_path) .. "/.keep")
end

return Storage
