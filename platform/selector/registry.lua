-- platform/selector/registry.lua
--
-- Capability map for selector internals.
-- No orchestration. No tracing.

local Registry = {}

Registry.validate_tokens = require("platform.selector.internal.validate_tokens")
Registry.walk            = require("platform.selector.internal.walk")
Registry.format_error = require("platform.selector.internal.format_error")

return Registry
