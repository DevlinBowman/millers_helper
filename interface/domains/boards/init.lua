-- interface/domains/boards/init.lua
--
-- Boards domain registration.

local Registry   = require("interface.registry")
local Controller = require("interface.domains.boards.controller")

Registry.register_domain("boards", {
    controller = Controller,
})

Registry.register("boards", "load",
    require("interface.domains.boards.load"))

Registry.register("boards", "inspect",
    require("interface.domains.boards.inspect"))

Registry.register("boards", "compare",
    require("interface.domains.boards.compare"))

Registry.register("boards", "invoice",
    require("interface.domains.boards.invoice"))
