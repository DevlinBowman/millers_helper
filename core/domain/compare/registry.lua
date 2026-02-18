-- core/domain/compare/registry.lua
--
-- Flat capability map (arc-spec).
-- No orchestration, no contracts, no tracing.

local Registry = {}

Registry.shape   = require("core.domain.compare.internal.shape")
Registry.input   = require("core.domain.compare.internal.input")
Registry.model   = require("core.domain.compare.internal.model")
Registry.matcher = require("core.domain.compare.internal.matcher")

Registry.formats = {
    layout = require("core.domain.compare.internal.formats.layout"),
    text   = require("core.domain.compare.internal.formats.text"),
}

return Registry
