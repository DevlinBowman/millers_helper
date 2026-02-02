-- cli/domains/ledger/init.lua
--
-- Ledger domain registration.
--
-- Responsibilities:
--   • Register the `ledger` domain with the CLI registry
--   • Attach the ledger domain controller
--   • Register ledger command adapters (ingest, inspect, export)
--
-- This file wires the domain together.
-- It contains no behavior and no business logic.

local Registry   = require("cli.registry")
local Controller = require("cli.domains.ledger.controller")

-- Register domain + controller
Registry.register_domain("ledger", {
    controller = Controller,
})

-- Register commands (interface only)
Registry.register("ledger", "ingest",
    require("cli.domains.ledger.ingest"))

Registry.register("ledger", "inspect",
    require("cli.domains.ledger.inspect"))

Registry.register("ledger", "export",
    require("cli.domains.ledger.export"))
