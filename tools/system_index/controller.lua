-- tools/system_index/controller.lua

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")
local Format   = require("tools.system_index.internal.format")

local BuildPipeline       = require("tools.system_index.pipelines.build")
local SyncCoveragePipeline = require("tools.system_index.pipelines.sync_coverage")

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {

    build = {
        in_  = { opts = false },
        out  = { modules = true },
    },

    sync_coverage = {
        in_  = { opts = false },
        out  = {
            stored     = true,
            discovered = true,
            diff       = true,
            wrote      = true,
        },
    },

    check_missing = {
        in_  = { opts = false },
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

----------------------------------------------------------------
-- Runtime Snapshot
----------------------------------------------------------------

--- Build a runtime snapshot by scanning package.loaded for arc modules.
--- @param opts table|nil { root?: string, prime_runtime?: boolean, verbose?: boolean }
--- @return table result { modules=table, prime=table|nil, summary=table }
function Controller.build(opts)
    Trace.contract_enter("system_index.build")
    Trace.contract_in(Controller.CONTRACT.build.in_)

    Contract.assert({ opts = opts }, Controller.CONTRACT.build.in_)

    local result = BuildPipeline.run(opts or {})

    Contract.assert(result, Controller.CONTRACT.build.out)
    Trace.contract_out(Controller.CONTRACT.build.out)

    return result
end

----------------------------------------------------------------
-- Coverage Sync (single-step update)
----------------------------------------------------------------

--- Discover modules, diff against stored coverage, optionally write coverage.
--- Default behavior: write coverage.
--- @param opts table|nil { root?: string, write?: boolean }
--- @return table result { stored=string[], discovered=string[], diff={missing=string[], new=string[]}, wrote=boolean }
function Controller.sync_coverage(opts)
    Trace.contract_enter("system_index.sync_coverage")
    Trace.contract_in(Controller.CONTRACT.sync_coverage.in_)

    Contract.assert({ opts = opts }, Controller.CONTRACT.sync_coverage.in_)

    local result = SyncCoveragePipeline.run(opts or {})

    Contract.assert(result, Controller.CONTRACT.sync_coverage.out)
    Trace.contract_out(Controller.CONTRACT.sync_coverage.out)

    return result
end

----------------------------------------------------------------
-- Back-compat: Missing Detection (no write)
----------------------------------------------------------------

--- Compatibility wrapper that returns only diff lists without writing coverage.
--- @param opts table|nil { root?: string }
--- @return table result { missing=string[], new=string[] }
function Controller.check_missing(opts)
    Trace.contract_enter("system_index.check_missing")
    Trace.contract_in(Controller.CONTRACT.check_missing.in_)

    Contract.assert({ opts = opts }, Controller.CONTRACT.check_missing.in_)

    local sync = Controller.sync_coverage({
        root  = (opts and opts.root) or ".",
        write = false,
    })

    local result = {
        missing = sync.diff.missing or {},
        new     = sync.diff.new or {},
    }

    Contract.assert(result, Controller.CONTRACT.check_missing.out)
    Trace.contract_out(Controller.CONTRACT.check_missing.out)

    return result
end

----------------------------------------------------------------
-- Presentation
----------------------------------------------------------------

--- Print snapshot (optional priming; default prime_runtime=true).
--- @param opts table|nil { root?: string, prime_runtime?: boolean, verbose?: boolean }
function Controller.print_snapshot(opts)
    local snapshot = Controller.build(opts)
    print(Format.render_snapshot(snapshot))
end

--- Print diff (never writes coverage).
--- @param opts table|nil { root?: string }
function Controller.print_diff(opts)
    local diff = Controller.check_missing(opts)
    print(Format.render_diff(diff))
end

--- Print diff and (optionally) update coverage in one shot.
--- @param opts table|nil { root?: string, write?: boolean }
function Controller.print_sync(opts)
    local sync = Controller.sync_coverage(opts)
    print(Format.render_diff(sync.diff))

    print("\nCOVERAGE SYNC")
    print("  wrote:      " .. tostring(sync.wrote))
    print("  discovered: " .. tostring(#(sync.discovered or {})))
    print("  stored:     " .. tostring(#(sync.stored or {})))

    if (sync.diff.missing and #sync.diff.missing > 0) then
        print_list("[system_index] Missing Modules", sync.diff.missing)
    end
    if (sync.diff.new and #sync.diff.new > 0) then
        print_list("[system_index] New Modules", sync.diff.new)
    end
end

return Controller
