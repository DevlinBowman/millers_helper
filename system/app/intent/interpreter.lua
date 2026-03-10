-- system/app/intent/interpreter.lua

local PricingDef = require("system.app.intent.definitions.pricing")

local Interpreter = {}

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function merge_defaults(def, user)

    local out = {}

    for field, spec in pairs(def.fields) do

        if user[field] ~= nil then
            out[field] = user[field]

        elseif spec.default ~= nil then
            out[field] = spec.default
        end

    end

    return out
end

------------------------------------------------------------
-- pricing context builder
------------------------------------------------------------

function Interpreter.pricing(runtime, intent)

    local user = intent.pricing or {}

    local ctx = merge_defaults(PricingDef, user)

    local ok, err = PricingDef.validate(runtime, ctx)

    if ok ~= true then
        return nil, err
    end

    return {
        pricing_basis = ctx.basis,
        percentage    = ctx.percentage,
        profile       = ctx.profile,
        vendor        = ctx.vendor
    }
end

------------------------------------------------------------
-- service dispatcher
------------------------------------------------------------

function Interpreter.build(service, runtime, intent)

    if service == "pricing" then
        return Interpreter.pricing(runtime, intent)
    end

    return {}
end

return Interpreter
