-- core/ledger/init.lua
--
-- Authoritative Ledger system entrypoint

local Registry = require("core.ledger.registry")

return {
    -- Orchestration surfaces
    controller = require("core.ledger.controller"),
    boundary   = require("core.ledger.boundary.surface"),

    -- Capability registry (introspectable)
    registry   = Registry,

    -- Direct capabilities (stable imports for interfaces)
    store      = Registry.store,
    ingest     = Registry.ingest,
    mutate     = Registry.mutate,

    analysis   = Registry.analysis,
    query      = Registry.query,
    inspect    = Registry.inspect,

    -- Exports (format-specific, read-only)
    exports = {
        csv = require("core.ledger.view.exports.csv"),
    },
}
