-- tools/system_index/pipelines/build.lua
--
-- Orchestration: optionally prime runtime, then scan loaded modules.

local Registry      = require("tools.system_index.registry")
local PrimeRuntime  = require("tools.system_index.pipelines.prime_runtime")

local Build = {}

local function count_map_keys(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

--- Build a runtime snapshot.
--- @param opts table|nil { root?: string, prime_runtime?: boolean, verbose?: boolean }
--- @return table result { modules=table, prime=table|nil, summary=table }
function Build.run(opts)
    opts = opts or {}

    local root          = opts.root or "."
    local prime_runtime = (opts.prime_runtime ~= false)
    local verbose       = opts.verbose == true

    local prime_result = nil
    if prime_runtime then
        prime_result = PrimeRuntime.run(root, {
            verbose = verbose,
            exclude_prefixes = { "tools.system_index" },
        })
    end

    local modules = Registry.scan()

    return {
        modules = modules,
        prime   = prime_result,
        summary = {
            indexed_modules = count_map_keys(modules),
        },
    }
end

return Build
