-- ledger/ledger.lua
--
-- Authoritative ledger shape.
-- Sparse, append-only facts with strong provenance.

local Ledger = {}

---@class LedgerFact
---@field fact_id string
---@field ingestion_id string
---@field content_key string
---@field data table            -- sparse flat data
---@field source table          -- provenance
---@field ingested_at string

---@class Ledger
---@field meta table
---@field facts LedgerFact[]
---@field ingestions table

function Ledger.new()
    return {
        meta = {
            created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            version = 1,
        },
        facts = {},
        ingestions = {},
    }
end

return Ledger
