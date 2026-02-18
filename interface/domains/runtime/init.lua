-- NOTE THIS DOMAIN IS ONLY HERE FOR TESTING PURPOSES
-- interface/domains/runtime/init.lua

local Registry   = require("interface.registry")
local Controller = require("interface.domains.runtime.controller")

Registry.register_domain("runtime", Controller)

Registry.register("runtime", "load",
    require("interface.domains.runtime.load"))
