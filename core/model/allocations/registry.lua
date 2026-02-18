-- core/model/allocations/registry.lua
--
-- Internal capability index.
-- No orchestration. No tracing. No contracts.

local Registry = {}

Registry.schema    = require("core.model.allocations.internal.schema")
Registry.presets   = require("core.model.allocations.internal.presets")
Registry.resolve   = require("core.model.allocations.internal.resolve")
Registry.validate  = require("core.model.allocations.internal.validate")

Registry.cost      = require("core.model.allocations.internal.cost")
Registry.format    = require("core.model.allocations.internal.format")

return Registry
