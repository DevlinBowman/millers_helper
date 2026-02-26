-- scripts/ignite_surface.lua

local Surface = require("system.app.surface")

local surface = Surface.new()

print("Surface alive.")
print("Ledger:", surface:status().ledger.ledger_id)

surface:save()
