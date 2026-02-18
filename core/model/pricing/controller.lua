-- core/model/pricing/controller.lua

local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local Registry = require("core.model.pricing.registry")

local Controller = {}

Controller.CONTRACT = {
    build_profile = {
        in_  = { profile_id = true },
        out  = { profile = true },
    },
    suggest = {
        in_  = {
            boards        = true,
            cost_surface  = true,  -- from allocations.cost_surface().surface
            profile       = true,
            ["matches?"]  = true,  -- optional retail match bundle
            ["opts?"]     = true,
        },
        out  = { suggestion = true },
    },
    format_suggestion = {
        in_  = { suggestion = true },
        out  = { text = true },
    },
}

----------------------------------------------------------------
-- Profile build
----------------------------------------------------------------

function Controller.build_profile(profile_id)

    Trace.contract_enter("core.model.pricing.controller.build_profile")
    Trace.contract_in({ profile_id = profile_id })

    local function run()
        assert(type(profile_id) == "string", "Pricing.build_profile(): profile_id required")

        Contract.assert({ profile_id = profile_id }, Controller.CONTRACT.build_profile.in_)

        local preset = Registry.presets[profile_id]
        assert(preset, "unknown pricing profile: " .. profile_id)

        local resolved = Registry.resolve.run(preset, Registry.presets)
        local normalized = Registry.schema.normalize_profile(resolved)

        Registry.validate.run(normalized, Registry.schema)

        Contract.assert({ profile = normalized }, Controller.CONTRACT.build_profile.out)
        Trace.contract_out({ profile = normalized })

        return { profile = normalized }
    end

    local ok, result = pcall(run)
    Trace.contract_leave()
    if not ok then error(result, 0) end
    return result
end

----------------------------------------------------------------
-- Suggest prices
----------------------------------------------------------------

function Controller.suggest(boards, cost_surface, profile, matches, opts)

    Trace.contract_enter("core.model.pricing.controller.suggest")
    Trace.contract_in({ boards = boards, cost_surface = cost_surface, profile = profile, matches = matches, opts = opts })

    local function run()
        assert(type(boards) == "table", "Pricing.suggest(): boards table required")
        assert(type(cost_surface) == "table", "Pricing.suggest(): cost_surface table required")
        assert(type(profile) == "table", "Pricing.suggest(): profile table required")
        if matches ~= nil then assert(type(matches) == "table", "Pricing.suggest(): matches must be table|nil") end
        if opts ~= nil then assert(type(opts) == "table", "Pricing.suggest(): opts must be table|nil") end

        local suggestion = Registry.engine.suggest(boards, cost_surface, profile, matches, opts)

        Contract.assert({ suggestion = suggestion }, Controller.CONTRACT.suggest.out)
        Trace.contract_out({ suggestion = suggestion })

        return { suggestion = suggestion }
    end

    local ok, result = pcall(run)
    Trace.contract_leave()
    if not ok then error(result, 0) end
    return result
end

----------------------------------------------------------------
-- Formatter (returns string)
----------------------------------------------------------------

function Controller.format_suggestion(suggestion)
    local text = Registry.format.suggestion(suggestion)
    return { text = text }
end

return Controller
