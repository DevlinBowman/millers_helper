local Registry = {}

Registry.schema   = require("core.domain.quote.internal.schema")
Registry.pipeline = require("core.domain.quote.pipelines.build")

return Registry
