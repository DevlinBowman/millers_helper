local Capabilities = require("system.execution.capabilities")

local Rules = {}

------------------------------------------------------------
-- Pricing Rule
------------------------------------------------------------

function Rules.pricing(ctx)

    local force =
        ctx.opts and ctx.opts.force == true

    local pricing_ready =
        Capabilities.batch_pricing_ready(ctx.target)

    if force then
        return { "pricing" }
    end

    if not pricing_ready then
        return { "pricing" }
    end

    return {}
end

------------------------------------------------------------
-- Quote Rule
------------------------------------------------------------

function Rules.quote(ctx)

    local force =
        ctx.opts and ctx.opts.force == true

    local pricing_ready =
        Capabilities.batch_pricing_ready(ctx.target)

    local pricing_intent =
        ctx.intent and ctx.intent.get and ctx.intent:get("pricing")

    if force then
        return { "pricing", "quote" }
    end

    if not pricing_ready and pricing_intent then
        return { "pricing", "quote" }
    end

    return { "quote" }
end

------------------------------------------------------------
-- Compare Rule
------------------------------------------------------------

function Rules.compare(ctx)

    local force =
        ctx.opts and ctx.opts.force == true

    local pricing_ready =
        Capabilities.batch_pricing_ready(ctx.target)

    local pricing_intent =
        ctx.intent and ctx.intent.get and ctx.intent:get("pricing")

    if force then
        return { "pricing", "compare" }
    end

    if not pricing_ready and pricing_intent then
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
