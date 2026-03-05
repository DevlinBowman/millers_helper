-- core/model/pricing/controller.lua
--
-- Pricing Model Controller
--
-- Exposes pure pricing math utilities.
-- No domain orchestration.

local Trace    = require("tools.trace.trace")

local Registry = require("core.model.pricing.registry")

local Controller = {}

----------------------------------------------------------------
-- Profile Builder
----------------------------------------------------------------

function Controller.profile_build(profile_id)

    Trace.contract_enter("core.model.pricing.controller.profile_build")

    assert(type(profile_id) == "string", "profile_id required")

    local preset = Registry.presets[profile_id]
    assert(preset, "unknown pricing profile: " .. profile_id)

    local resolved =
        Registry.resolve.run(preset, Registry.presets)

    local normalized =
        Registry.schema.normalize_profile(resolved)

    Registry.validate.run(normalized, Registry.schema)

    Trace.contract_leave()

    return normalized
end

----------------------------------------------------------------
-- Curve utilities
----------------------------------------------------------------

function Controller.curve_match_piecewise(curve, value)
    return Registry.curve.match_piecewise(curve, value)
end

function Controller.curve_match_map(map, key)
    return Registry.curve.match_map(map, key)
end

----------------------------------------------------------------
-- Envelope helpers
----------------------------------------------------------------

function Controller.envelope_items(env, expected_kind, label)
    return Registry.envelope.items(env, expected_kind, label)
end

function Controller.envelope_meta(env, expected_kind, label)
    return Registry.envelope.meta(env, expected_kind, label)
end

return Controller
