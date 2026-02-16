local Registry = {}

Registry.build       = require("core.domain.ledger.internal.build")
Registry.identity    = require("core.domain.ledger.internal.identity")
Registry.storage     = require("core.domain.ledger.internal.storage")
Registry.ledger      = require("core.domain.ledger.internal.ledger")
Registry.attachments = require("core.domain.ledger.internal.attachments")

return Registry
