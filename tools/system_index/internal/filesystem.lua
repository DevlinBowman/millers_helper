-- tools/system_index/internal/filesystem.lua
--
-- Pure filesystem discovery of arc-spec modules.

local lfs = require("lfs")

local Filesystem = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function is_arc_directory(path)
    return
        file_exists(path .. "/init.lua") and
        file_exists(path .. "/controller.lua") and
        file_exists(path .. "/registry.lua")
end

local function normalize_module_name(root, path)
    local relative = path:sub(#root + 2)
    return relative:gsub("/", ".")
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

--- Recursively discover arc-spec modules
--- @param root string
--- @return table<string>
function Filesystem.discover(root)
    local modules = {}

    local function scan(directory)
        for entry in lfs.dir(directory) do
            if entry ~= "." and entry ~= ".." then
                local full_path = directory .. "/" .. entry
                local attributes = lfs.attributes(full_path)

                if attributes and attributes.mode == "directory" then
                    if is_arc_directory(full_path) then
                        modules[#modules + 1] =
                            normalize_module_name(root, full_path)
                    end

                    scan(full_path)
                end
            end
        end
    end

    scan(root)

    table.sort(modules)
    return modules
end

return Filesystem
