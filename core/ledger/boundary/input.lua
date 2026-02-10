local Ingest = require("core.ledger.internal.ingest.ingest")

return {
  ingest = Ingest.run,
}
