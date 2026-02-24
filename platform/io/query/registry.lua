-- platform/io/query/registry.lua
--
-- Capability map for query internals.
-- Exposes internal layer only.
-- No orchestration. No tracing.

local Registry = {}

Registry.classify  = require("platform.io.query.internal.classify")
Registry.enumerate = require("platform.io.query.internal.enumerate")

return Registry
