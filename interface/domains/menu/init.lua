-- interface/domains/menu/init.lua

local Registry   = require("interface.registry")
local Controller = require("interface.domains.menu.controller")

Registry.register_domain("menu", Controller)

Registry.register("menu", nil, {
    run = function(ctx, controller)
        return controller:run(ctx)
    end
})
