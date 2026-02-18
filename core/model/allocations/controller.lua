-- core/model/allocations/controller.lua

local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local Registry = require("core.model.allocations.registry")

local Controller = {}

Controller.CONTRACT = {
    build = {
        in_  = { profile_id = true },
        out  = { profile = true },
    },
    cost_surface = {
        in_  = { order = true, boards = true, profile = true },
        out  = { surface = true },
    },
}

----------------------------------------------------------------
-- Build Profile
----------------------------------------------------------------

function Controller.build(profile_id)

    Trace.contract_enter("core.model.allocations.controller.build")
    Trace.contract_in({ profile_id = profile_id })

    local function run()

        assert(type(profile_id) == "string")

        local preset = Registry.presets[profile_id]
        assert(preset, "unknown allocation profile: " .. profile_id)

        local resolved = Registry.resolve.run(
            preset,
            Registry.presets
        )

        local normalized = Registry.schema.normalize_profile(resolved)

        Registry.validate.run(normalized, Registry.schema)

        table.sort(normalized.allocations, function(a, b)
            return (a.priority or 0) < (b.priority or 0)
        end)

        return { profile = normalized }
    end

    local ok, result = pcall(run)
    Trace.contract_leave()

    if not ok then
        error(result, 0)
    end

    return result
end

----------------------------------------------------------------
-- Cost Surface
----------------------------------------------------------------

function Controller.cost_surface(order, boards, profile)

    Trace.contract_enter("core.model.allocations.controller.cost_surface")
    Trace.contract_in({ order = order, boards = boards, profile = profile })

    local surface = Registry.cost.compute(order, boards, profile)

    Trace.contract_leave()

    return { surface = surface }
end

----------------------------------------------------------------
-- Format Cost Surface
----------------------------------------------------------------

function Controller.format_cost_surface(surface)
    return Registry.format.cost_surface(surface)
end

return Controller
