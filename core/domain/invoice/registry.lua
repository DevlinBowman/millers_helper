local Registry = {}

Registry.schema   = require("core.domain.invoice.internal.schema")
Registry.pipeline = require("core.domain.invoice.pipelines.build")

return Registry
