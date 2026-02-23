local Storage      = require("system.infrastructure.storage.controller")
local ResourceSpec = require("system.app.resource_spec")
local FS           = require("platform.io.registry").fs

local Resources = {}
Resources.__index = Resources

local function list_vendor_cache_csv_paths()
    local root = Storage.vendor_cache_root()

    if not (FS.dir_exists and FS.dir_exists(root)) then
        return {}
    end

    local entries = FS.list_dir(root)
    if not entries then
        return {}
    end

    local paths = {}
    for _, entry in ipairs(entries) do
        local filename = FS.get_filename(entry) or entry
        if filename:match("%.csv$") then
            paths[#paths + 1] = root .. "/" .. filename
        end
    end

    table.sort(paths)
    return paths
end

function Resources.new(surface)
    local self = setmetatable({}, Resources)
    self._surface = surface

    self.user = {
        order = {
            set_path = function(_, path)
                local spec = ResourceSpec.simple(path, "order", { source = "user" })
                local ok, err = surface.state:set_resource("user.order", spec)
                if ok then surface.hub._cache["user.order"] = nil end
                return ok, err
            end,
            clear = function()
                local ok, err = surface.state:clear_resource("user.order")
                if ok then surface.hub._cache["user.order"] = nil end
                return ok, err
            end,
            get = function()
                return surface.state:get_resource("user.order")
            end,
        },

        vendors = {
            set_path = function(_, path)
                local spec = ResourceSpec.simple(path, "board", { source = "user.override" })
                local ok, err = surface.state:set_resource("user.vendors", spec)
                if ok then surface.hub._cache["user.vendors"] = nil end
                return ok, err
            end,
            set_paths = function(_, paths)
                local spec = ResourceSpec.multi(paths, "board", { source = "user.override" })
                local ok, err = surface.state:set_resource("user.vendors", spec)
                if ok then surface.hub._cache["user.vendors"] = nil end
                return ok, err
            end,
            clear = function()
                local ok, err = surface.state:clear_resource("user.vendors")
                if ok then surface.hub._cache["user.vendors"] = nil end
                return ok, err
            end,
            get = function()
                return surface.state:get_resource("user.vendors")
            end,
        },
    }

    self.system = {
        vendors = {
            refresh_from_cache = function()
                local paths = list_vendor_cache_csv_paths()
                local spec = ResourceSpec.multi(paths, "board", { source = "system.vendor_cache" })
                local ok, err = surface.state:set_resource("system.vendors", spec)
                if ok then surface.hub._cache["system.vendors"] = nil end
                return ok, err
            end,
            get = function()
                return surface.state:get_resource("system.vendors")
            end,
        },
    }

    return self
end

return Resources
