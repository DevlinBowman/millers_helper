-- core/model/pricing/registry.lua

local Registry = {}

Registry.schema   = require("core.model.pricing.internal.schema")
Registry.presets  = require("core.model.pricing.internal.presets")
Registry.resolve  = require("core.model.pricing.internal.resolve")
Registry.validate = require("core.model.pricing.internal.validate")
Registry.curve    = require("core.model.pricing.internal.curve")

Registry.envelope = require("core.model.pricing.internal.envelope")
Registry.result   = require("core.model.pricing.result")

return Registry
