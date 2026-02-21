-- classify/registry.lua
--
-- Internal capability façade.
-- No orchestration. No logic.

local Registry = {}

Registry.alias     = require("platform.classify.internal.alias")
Registry.spec      = require("platform.classify.internal.schema")
Registry.partition = require("platform.classify.internal.partition")

return Registry
