-- classify/registry.lua
--
-- Internal capability façade.
-- No orchestration. No logic.

local Registry = {}

Registry.alias     = require("classify.internal.alias")
Registry.spec      = require("classify.internal.spec")
Registry.partition = require("classify.internal.partition")

return Registry
