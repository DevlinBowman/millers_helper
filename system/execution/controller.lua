local Compatibility = require("system.compatibility.controller")
local Enrichment    = require("system.enrichment.controller")

local Executor = {}

function Executor.run(app, service_name, selector, opts)

    local service = app:services()[service_name](app:services())

    local env = service:_build_env(selector, opts)

    local compat = Compatibility.check(service_name, "default", env)

    if not compat.ok then

        local enrichment =
            Enrichment.resolve(app, selector, {
                missing = compat.missing,
                env     = env,
                opts    = opts
            })

        if not enrichment.ok then
            return {
                ok=false,
                error="compatibility_mismatch",
                missing=compat.missing
            }
        end

        env = service:_build_env(selector, opts)

        compat = Compatibility.check(service_name, "default", env)

        if not compat.ok then
            return {
                ok=false,
                error="compatibility_mismatch_after_enrichment",
                missing=compat.missing
            }
        end
    end

    return service:run(selector, opts)
end

return Executor
