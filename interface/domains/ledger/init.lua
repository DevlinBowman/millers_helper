local Registry   = require("interface.registry")
local Controller = require("interface.domains.ledger.controller")

Registry.register_domain("ledger", Controller)

Registry.register("ledger", "inspect", {
    run = function(ctx, controller)
        return controller:inspect(ctx)
    end
})

Registry.register("ledger", "ingest", {
    run = function(ctx, controller)
        return controller:ingest(ctx)
    end
})

Registry.register("ledger", "browse", {
    run = function(ctx, controller)
        return controller:browse(ctx)
    end
})
