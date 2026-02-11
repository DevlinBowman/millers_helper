-- core/ledger/registry.lua
--
-- Authoritative internal capability registry for Ledger domain.
-- All entries here are:
--   • intentionally callable
--   • stable within the domain
--   • UI-agnostic

return {

    ----------------------------------------------------------------
    -- State lifecycle
    ----------------------------------------------------------------
    model = {
        ledger   = require("core.ledger.internal.model.ledger"),
        identity = require("core.ledger.internal.model.identity"),
    },

    store = require("core.ledger.internal.persistance.store"),

    ----------------------------------------------------------------
    -- Write capabilities
    ----------------------------------------------------------------
    ingest = require("core.ledger.internal.ingest.ingest"),
    mutate = require("core.ledger.internal.mutation.mutate"),

    ----------------------------------------------------------------
    -- Read / analysis capabilities
    ----------------------------------------------------------------
    analysis = {
        keys     = require("core.ledger.analysis.keys"),
        summary  = require("core.ledger.analysis.summary"),
        describe = require("core.ledger.analysis.describe"),
    },

    query = require("core.ledger.boundary.query"),

    inspect = require("core.ledger.view.inspect"),

    ----------------------------------------------------------------
    -- Optional decision helpers
    ----------------------------------------------------------------
    review = require("core.ledger.internal.helpers.review"),
}
