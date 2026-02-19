local Registry   = require("interface.registry")
local Controller = require("interface.domains.ledger.controller")

Registry.register_domain("ledger", Controller)

Registry.register("ledger", "ledger", {
    run = function(ctx, controller)
        return controller:ledger(ctx)
    end
})

Registry.register("ledger", "inspect", {
    run = function(ctx, controller)
        return controller:inspect(ctx)
    end
})

Registry.register("ledger", "list", {
    run = function(ctx, controller)
        return controller:inspect(ctx)
    end
})

Registry.register("ledger", "open", {
    run = function(ctx, controller)
        return controller:open(ctx)
    end
})

Registry.register("ledger", "commit", {
    run = function(ctx, controller)
        return controller:commit(ctx)
    end
})

Registry.register("ledger", "analytics", {
    run = function(ctx, controller)
        return controller:analytics(ctx)
    end
})

Registry.register("ledger", "browser", {
    run = function(ctx, controller)
        return controller:browser(ctx)
    end
})
