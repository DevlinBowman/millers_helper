-- tools/system_index/pipelines/prime_runtime.lua
--
-- Orchestration: discover arc modules on disk and require() them to prime package.loaded.
-- Side-effectful by design (pcall(require)).

local Filesystem = require("tools.system_index.internal.filesystem")

local PrimeRuntime = {}

local function print_list(title, list)
    print("\n" .. title .. " (" .. #list .. ")")
    for _, name in ipairs(list) do
        print("  - " .. name)
    end
end

--- Prime runtime by requiring discovered arc modules.
--- @param root string
--- @param opts table|nil { verbose?: boolean, exclude_prefixes?: string[] }
--- @return table result { discovered=string[], loaded_now=string[], skipped=string[], failed={ {name=string, err=string} } }
function PrimeRuntime.run(root, opts)
    opts = opts or {}
    local verbose = opts.verbose == true
    local exclude_prefixes = opts.exclude_prefixes or { "tools.system_index" }

    local discovered = Filesystem.discover(root)

    local loaded_now = {}
    local skipped    = {}
    local failed     = {}

    local function is_excluded(module_name)
        for _, prefix in ipairs(exclude_prefixes) do
            if module_name:match("^" .. prefix) then
                return true
            end
        end
        return false
    end

    if verbose then
        print("\n[system_index] ARC MODULES FOUND:")
        for _, name in ipairs(discovered) do
            print("  - " .. name)
        end
    end

    for _, module_name in ipairs(discovered) do
        if is_excluded(module_name) then
            skipped[#skipped + 1] = module_name
        elseif package.loaded[module_name] then
            skipped[#skipped + 1] = module_name
        else
            local ok, err = pcall(require, module_name)
            if ok then
                loaded_now[#loaded_now + 1] = module_name
            else
                failed[#failed + 1] = { name = module_name, err = tostring(err) }
                if verbose then
                    print("\n  ✗ REQUIRE FAILED:", module_name)
                    print("    →", tostring(err))
                end
            end
        end
    end

    if verbose then
        print_list("[system_index] Newly Loaded", loaded_now)
        print_list("[system_index] Skipped (already loaded or excluded)", skipped)

        local failed_names = {}
        for _, item in ipairs(failed) do failed_names[#failed_names + 1] = item.name end
        print_list("[system_index] Failed", failed_names)

        print("\n[system_index] Require Summary")
        print("  Found:        " .. #discovered)
        print("  Loaded now:   " .. #loaded_now)
        print("  Skipped:      " .. #skipped)
        print("  Failed:       " .. #failed)
    end

    return {
        discovered = discovered,
        loaded_now = loaded_now,
        skipped    = skipped,
        failed     = failed,
    }
end

return PrimeRuntime
