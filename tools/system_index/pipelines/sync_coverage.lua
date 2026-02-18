-- tools/system_index/pipelines/sync_coverage.lua
--
-- Orchestration: discover modules on disk, diff against stored coverage, optionally write coverage.

local Filesystem = require("tools.system_index.internal.filesystem")
local Persist    = require("tools.system_index.internal.persist")

local SyncCoverage = {}

local function list_to_set(list)
    local set = {}
    for _, value in ipairs(list or {}) do
        set[value] = true
    end
    return set
end

local function compute_diff(discovered, stored)
    local discovered_set = list_to_set(discovered)
    local stored_set     = list_to_set(stored)

    local missing = {}
    local new     = {}

    for name in pairs(stored_set) do
        if not discovered_set[name] then
            missing[#missing + 1] = name
        end
    end

    for name in pairs(discovered_set) do
        if not stored_set[name] then
            new[#new + 1] = name
        end
    end

    table.sort(missing)
    table.sort(new)

    return { missing = missing, new = new }
end

--- Sync coverage file with current discovery.
--- @param opts table|nil { root?: string, write?: boolean }
--- @return table result { stored=string[], discovered=string[], diff={missing=string[], new=string[]}, wrote=boolean }
function SyncCoverage.run(opts)
    opts = opts or {}

    local root  = opts.root or "."
    local write = (opts.write ~= false)

    local discovered = Filesystem.discover(root)
    local stored     = Persist.load()

    local diff = compute_diff(discovered, stored)

    local wrote = false
    if write then
        Persist.save(discovered)
        wrote = true
        stored = discovered
    end

    return {
        stored     = stored,
        discovered = discovered,
        diff       = diff,
        wrote      = wrote,
    }
end

return SyncCoverage
