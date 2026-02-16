-- classify/registry.lua
--
-- Internal capability façade.
-- No orchestration. No logic.

local Registry = {}

Registry.alias     = require("classify.internal.alias")
Registry.spec      = require("classify.internal.schema")
Registry.partition = require("classify.internal.partition")

return Registry
