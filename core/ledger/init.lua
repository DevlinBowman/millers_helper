-- core/ledger/init.lua
--
-- Authoritative Ledger system entrypoint

return {
    controller = require("core.ledger.controller"),
    boundary   = require("core.ledger.boundary.surface"),
}
