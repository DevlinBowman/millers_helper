-- core/domain/pricing/controller.lua

local Trace = require("tools.trace.trace")

local Registry     = require("core.domain.pricing.registry")
local DomainResult = require("core.domain.pricing.result")

local PricingModel      = require("core.model.pricing.controller")
local PricingModelResult = require("core.model.pricing.result")

local Controller = {}

----------------------------------------------------------------
-- RAW
----------------------------------------------------------------

function Controller.run_raw(source, basis, opts)
    Trace.contract_enter("core.domain.pricing.controller.run_raw")

    opts = opts or {}

    local boards = Registry.input.extract_boards(source)

    local strategy = Registry.strategies[basis]
    assert(strategy, "[pricing.domain] unknown pricing basis: " .. tostring(basis))

    local profile_id = opts.profile or "default"
    local profile = PricingModel.profile_build(profile_id)

    local env = {
        basis   = basis,
        profile = profile,

        boards = {
            kind  = "boards",
            items = boards,
        },

        allocations = opts.allocations,
        vendor      = opts.vendor,
        compare     = opts.compare,

        opts = opts,
    }

    local raw = strategy.run(env)

    Trace.contract_leave()

    return raw
end

----------------------------------------------------------------
-- RESULT WRAPPER
----------------------------------------------------------------

function Controller.run(source, basis, opts)
    local raw = Controller.run_raw(source, basis, opts)

    local model_result = PricingModelResult.new(raw)

    return DomainResult.new(model_result)
end

----------------------------------------------------------------
-- STRICT
----------------------------------------------------------------

function Controller.run_strict(source, basis, opts)
    local result, err = pcall(function()
        return Controller.run(source, basis, opts)
    end)

    if not result then
        error(err, 2)
    end

    return err
end

return Controller
