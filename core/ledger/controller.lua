-- core/ledger/controller.lua
--
-- Ledger system controller.
-- Orchestrates ledger intent via boundary surfaces.
-- UI-agnostic. No interface imports.

local Boundary = require("core.ledger.boundary.surface")

local Controller = {}

function Controller.ingest(ledger, boards, source)
    return Boundary.input.ingest(ledger, boards, source)
end

function Controller.query(ledger, predicate)
    return Boundary.output.query.where(ledger, predicate)
end

function Controller.inspect(ledger)
    return Boundary.output.inspect.summary(ledger)
end

return Controller
