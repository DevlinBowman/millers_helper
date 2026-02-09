-- interface/domains/ledger/init.lua
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

local Registry   = require("interface.registry")
local Controller = require("interface.domains.ledger.controller")

-- Register domain + controller
Registry.register_domain("ledger", {
    controller = Controller,
})

-- Register commands (interface only)
Registry.register("ledger", "ingest",
    require("interface.domains.ledger.ingest"))

Registry.register("ledger", "inspect",
    require("interface.domains.ledger.inspect"))

Registry.register("ledger", "export",
    require("interface.domains.ledger.export"))
