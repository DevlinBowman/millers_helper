-- system/backend.lua
--
-- Canonical backend bootstrap entrypoint.

local Storage = require("system.infrastructure.storage.controller")
local AppFS   = require("system.infrastructure.app_fs.controller")
local Surface = require("system.app.surface")

---@class Backend
local Backend = {}

------------------------------------------------------------
-- Internal bootstrap
------------------------------------------------------------

---@param instance_name string
local function initialize_instance(instance_name)
    Storage.set_instance(instance_name)
    AppFS.ensure_instance_layout()
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

---@param instance_name string|nil
---@return Surface
function Backend.run(instance_name)
    instance_name = instance_name or "default"

    initialize_instance(instance_name)

    local surface = Surface.new(instance_name)

    -- register system file pointers only
    surface:data():resources():pull_system()

    return surface
end

---@param instance_name string|nil
---@return Surface
function Backend.run_strict(instance_name)
    local ok, result = pcall(function()
        return Backend.run(instance_name)
    end)

    if not ok then
        error("[backend] failed to initialize: " .. tostring(result), 2)
    end

    return result
end

return Backend
