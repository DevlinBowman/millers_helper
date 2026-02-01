-- cli/domains/ledger/init.lua

local Registry = require("cli.registry")

local ingest  = require("cli.domains.ledger.ingest")
local inspect = require("cli.domains.ledger.inspect")
local export  = require("cli.domains.ledger.export")

Registry.register("ledger", "ingest",  ingest)
Registry.register("ledger", "inspect", inspect)
Registry.register("ledger", "export",  export)
