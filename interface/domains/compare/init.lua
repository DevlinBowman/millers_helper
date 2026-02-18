-- interface/domains/compare/init.lua

local Registry   = require("interface.registry")
local Controller = require("interface.domains.compare.controller")

Registry.register_domain("compare", Controller)

-- default action when no subcommand is provided
Registry.register("compare", nil, {
    run = function(ctx, controller)
        return controller:run(ctx)
    end
})
