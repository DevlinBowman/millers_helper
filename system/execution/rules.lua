local Capabilities = require("system.execution.capabilities")

local Rules = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function is_force(ctx)
    return ctx.opts and ctx.opts.force == true
end

local function pricing_ready(ctx)
    return Capabilities.batch_pricing_ready(ctx.target)
end

local function pricing_intent(ctx)
    return ctx.intent
       and ctx.intent.get
       and ctx.intent:get("pricing")
end

------------------------------------------------------------
-- Pricing Rule
------------------------------------------------------------

function Rules.pricing(ctx)

    if is_force(ctx) then
        return { "pricing" }
    end

    if not pricing_ready(ctx) then
        return { "pricing" }
    end

    return {}
end

------------------------------------------------------------
-- Quote Rule
------------------------------------------------------------

function Rules.quote(ctx)

    if is_force(ctx) then
        return { "pricing", "quote" }
    end

    if not pricing_ready(ctx) and pricing_intent(ctx) then
        return { "pricing", "quote" }
    end

    return { "quote" }
end

------------------------------------------------------------
-- Compare Rule
------------------------------------------------------------

function Rules.compare(ctx)

    if is_force(ctx) then
        return { "pricing", "compare" }
    end

    if not pricing_ready(ctx) and pricing_intent(ctx) then
        return { "pricing", "compare" }
    end

    return { "compare" }
end

------------------------------------------------------------
-- Entry
------------------------------------------------------------

function Rules.plan(service, ctx)

    local fn = Rules[service]

    if not fn then
        return { service }
    end

    return fn(ctx)
end

return Rules
