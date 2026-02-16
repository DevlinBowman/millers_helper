-- core/model/order/registry.lua
--
-- Internal capability index for the order model.
-- No orchestration. No tracing. No contracts.

local Registry = {}

Registry.schema  = require("core.model.order.internal.schema")
Registry.coerce  = require("core.model.order.internal.coerce")
Registry.derive = require("core.model.order.internal.derive")
Registry.validate = require("core.model.order.internal.validate")

return Registry
