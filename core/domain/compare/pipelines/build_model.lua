-- core/domain/compare/pipelines/build_model.lua
--
-- Composes model builder.
-- No validation. No tracing.

local Registry = require("core.domain.compare.registry")

local Pipeline = {}

function Pipeline.run(input)
    return Registry.model.build(input)
end

return Pipeline
