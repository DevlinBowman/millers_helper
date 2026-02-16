-- order_context/registry.lua
--
-- Capability map. No orchestration.

local Registry = {}

Registry.policy = require("order_context.internal.policy")
Registry.util   = require("order_context.internal.util")
Registry.signal = require("order_context.internal.signal")
Registry.spec = require("order_context.internal.spec")

return Registry
