-- system/app/system_defaults.lua
--
-- Applies system-owned default resource specs into State.resources.system.
-- Canonical reference store loader.

local Storage      = require("system.infrastructure.storage.controller")
local FS           = require("platform.io.registry").fs
local ResourceSpec = require("system.app.resource_spec")

local Defaults = {}

----------------------------------------------------------------
-- Discover vendor cache CSV files
----------------------------------------------------------------
local function list_vendor_cache_csv_paths()
    local root = Storage.vendor_cache_root()

    print("SCAN ROOT:", root)

    if not FS.is_dir(root) then
        print("DIR DOES NOT EXIST")
        return {}
    end

    local entries = FS.list_dir(root)

    print("RAW ENTRIES TABLE:", entries)
    if type(entries) ~= "table" then
        print("ENTRIES NOT TABLE")
        return {}
    end

    local paths = {}

    for i, entry in ipairs(entries) do
        print("ENTRY", i, "VALUE:", entry, "TYPE:", type(entry))

        if type(entry) == "string" then
            local lower = entry:lower()
            print("LOWER:", lower)

            if lower:match("%.csv$") then
                print("MATCHED CSV:", entry)
                paths[#paths + 1] = entry
            else
                print("NO MATCH")
            end
        end
    end

    print("FINAL PATH COUNT:", #paths)

    return paths
end

----------------------------------------------------------------
-- Apply defaults
----------------------------------------------------------------
---@param surface Surface
function Defaults.apply(surface)
    if not surface or not surface.state then
        return false, "missing surface/state"
    end

    local vendor_paths = list_vendor_cache_csv_paths()

    if #vendor_paths > 0 then
        local spec = ResourceSpec.multi(
            vendor_paths,
            "board",
            { source = "system.vendor_cache" }
        )

        surface.state:set_resource("system.vendors", spec)
    else
        -- Clear spec if directory empty
        surface.state:clear_resource("system.vendors")
    end

    if surface.hub and surface.hub.invalidate then
        surface.hub:invalidate("system.vendors")
    end

    return true
end

return Defaults
