-- cli/domains/boards/init.lua
--
-- Boards domain registration.

local Registry   = require("cli.registry")
local Controller = require("cli.domains.boards.controller")

Registry.register_domain("boards", {
    controller = Controller,
})

Registry.register("boards", "load",
    require("cli.domains.boards.load"))

Registry.register("boards", "inspect",
    require("cli.domains.boards.inspect"))

Registry.register("boards", "compare",
    require("cli.domains.boards.compare"))

Registry.register("boards", "invoice",
    require("cli.domains.boards.invoice"))
