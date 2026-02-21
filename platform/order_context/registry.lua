-- order_context/registry.lua
--
-- Capability map. No orchestration.

local Registry = {}

Registry.policy = require("platform.order_context.internal.policy")
Registry.util   = require("platform.order_context.internal.util")
Registry.signal = require("platform.order_context.internal.signal")
Registry.spec = require("platform.order_context.internal.spec")

return Registry
