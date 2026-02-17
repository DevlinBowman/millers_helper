-- tools/system_index/controller.lua

local Trace      = require("tools.trace.trace")
local Contract   = require("core.contract")
local Registry   = require("tools.system_index.registry")

local Filesystem = require("tools.system_index.internal.filesystem")
local Persist    = require("tools.system_index.internal.persist")
local Format     = require("tools.system_index.internal.format")

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {

    build = {
        in_  = {},
        out  = { modules = true },
    },

    update_coverage = {
        in_  = {},
        out  = { stored = true },
    },

    check_missing = {
        in_  = {},
        out  = {
            missing = true,
            new     = true,
        },
    },
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function print_list(title, list)
    print("\n" .. title .. " (" .. #list .. ")")
    for _, name in ipairs(list) do
        print("  - " .. name)
    end
end

local function safe_require_all_arc_modules(root)
    local discovered = Filesystem.discover(root)

    print("\n[system_index] ARC MODULES FOUND:")
    for _, name in ipairs(discovered) do
        print("  - " .. name)
    end

    local loaded_now = {}
    local skipped    = {}
    local failed     = {}

    for _, module_name in ipairs(discovered) do
        if module_name:match("^tools%.system_index") then
            skipped[#skipped + 1] = module_name

        elseif package.loaded[module_name] then
            skipped[#skipped + 1] = module_name

        else
            local ok, err = pcall(require, module_name)

            if ok then
                loaded_now[#loaded_now + 1] = module_name
            else
                failed[#failed + 1] = module_name
                print("\n  ✗ REQUIRE FAILED:", module_name)
                print("    →", tostring(err))
            end
        end
    end

    print_list("[system_index] Newly Loaded", loaded_now)
    print_list("[system_index] Skipped (already loaded or excluded)", skipped)
    print_list("[system_index] Failed", failed)

    print("\n[system_index] Require Summary")
    print("  Found:        " .. #discovered)
    print("  Loaded now:   " .. #loaded_now)
    print("  Skipped:      " .. #skipped)
    print("  Failed:       " .. #failed)

    return discovered
end

local function count_map_keys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

local function list_to_set(list)
    local set = {}
    for _, value in ipairs(list) do
        set[value] = true
    end
    return set
end

----------------------------------------------------------------
-- Runtime Snapshot
----------------------------------------------------------------

function Controller.build()
    Trace.contract_enter("system_index.build")
    Trace.contract_in(Controller.CONTRACT.build.in_)

    print("\n=== SYSTEM INDEX BUILD ===")

    safe_require_all_arc_modules(".")

    local modules = Registry.scan()

    print("\n[system_index] RUNTIME SNAPSHOT MODULES:")
    local snapshot_names = {}
    for name in pairs(modules) do
        snapshot_names[#snapshot_names + 1] = name
    end
    table.sort(snapshot_names)

    for _, name in ipairs(snapshot_names) do
        print("  - " .. name)
    end

    print("\n[system_index] Snapshot Summary")
    print("  Indexed modules: " .. count_map_keys(modules))

    local result = {
        modules = modules,
    }

    Contract.assert(result, Controller.CONTRACT.build.out)
    Trace.contract_out(Controller.CONTRACT.build.out)

    print("=== BUILD COMPLETE ===\n")

    return result
end

----------------------------------------------------------------
-- Coverage Update
----------------------------------------------------------------

function Controller.update_coverage()
    Trace.contract_enter("system_index.update_coverage")
    Trace.contract_in(Controller.CONTRACT.update_coverage.in_)

    print("\n=== SYSTEM INDEX COVERAGE UPDATE ===")

    local discovered = Filesystem.discover(".")

    print("\n[system_index] Writing coverage file:")
    for _, name in ipairs(discovered) do
        print("  - " .. name)
    end

    Persist.save(discovered)

    print("\n[system_index] Coverage saved (" .. #discovered .. " modules)")
    print("=== COVERAGE UPDATE COMPLETE ===\n")

    local result = {
        stored = discovered,
    }

    Contract.assert(result, Controller.CONTRACT.update_coverage.out)
    Trace.contract_out(Controller.CONTRACT.update_coverage.out)

    return result
end

----------------------------------------------------------------
-- Missing Detection
----------------------------------------------------------------

function Controller.check_missing()
    Trace.contract_enter("system_index.check_missing")
    Trace.contract_in(Controller.CONTRACT.check_missing.in_)

    print("\n=== SYSTEM INDEX DIFF ===")

    local discovered     = Filesystem.discover(".")
    local stored         = Persist.load()

    local discovered_set = list_to_set(discovered)
    local stored_set     = list_to_set(stored)

    local missing        = {}
    local new            = {}

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

    print_list("[system_index] Missing Modules", missing)
    print_list("[system_index] New Modules", new)

    print("\n[system_index] Diff Summary")
    print("  Missing: " .. #missing)
    print("  New:     " .. #new)
    print("=== DIFF COMPLETE ===\n")

    local result = {
        missing = missing,
        new     = new,
    }

    Contract.assert(result, Controller.CONTRACT.check_missing.out)
    Trace.contract_out(Controller.CONTRACT.check_missing.out)

    return result
end

----------------------------------------------------------------
-- Presentation
----------------------------------------------------------------

function Controller.print_snapshot()
    local snapshot = Controller.build()
    local text = Format.render_snapshot(snapshot)
    print(text)
end

function Controller.print_diff()
    local diff = Controller.check_missing()
    local text = Format.render_diff(diff)
    print(text)
end

return Controller
