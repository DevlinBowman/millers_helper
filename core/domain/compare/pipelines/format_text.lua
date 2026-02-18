-- core/domain/compare/pipelines/format_text.lua
--
-- Composes formatter.
-- No validation. No tracing.

local Registry = require("core.domain.compare.registry")

local Pipeline = {}

function Pipeline.run(model, opts)
    return Registry.formats.text.format(model, opts)
end

return Pipeline
