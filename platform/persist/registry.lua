-- platform/persist/registry.lua
--
-- Capability map for persist module.
-- No orchestration. No tracing.

local Registry = {}

Registry.format = require("platform.format.controller")
Registry.io     = require("platform.io.controller")

return Registry
