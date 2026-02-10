-- ledger/ledger.lua
--
-- Authoritative ledger shape.
-- Append-only, immutable facts.

local Ledger = {}

---@class LedgerFact
---@field fact_id string
---@field content_key string
---@field board table
---@field source table
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
