-- core/model/pricing/registry.lua

local Registry = {}

Registry.curve    = require("core.model.pricing.internal.curve")

Registry.envelope = require("core.model.pricing.internal.envelope")
Registry.result   = require("core.model.pricing.result")

return Registry
