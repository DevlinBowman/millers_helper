-- ledger/inspect.lua
--
-- Read-only inspection helpers for the ledger.
-- No mutation. No inference beyond ledger state.

local Inspect = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function short(s, n)
    if type(s) ~= "string" then return s end
    n = n or 80
    if #s <= n then return s end
    return s:sub(1, n - 3) .. "..."
end

----------------------------------------------------------------
-- High-level summary
----------------------------------------------------------------

---@param ledger table
---@return table
function Inspect.summary(ledger)
    return {
        created_at = ledger.meta and ledger.meta.created_at,
        version    = ledger.meta and ledger.meta.version,
        facts      = #ledger.facts,
        ingestions = #ledger.ingestions,
    }
end

----------------------------------------------------------------
-- Compact fact listing (spreadsheet-like)
----------------------------------------------------------------

---@param ledger table
---@return table[]
function Inspect.list_facts(ledger)
    local rows = {}

    for i, fact in ipairs(ledger.facts) do
        local b = fact.board

        rows[#rows + 1] = {
            index       = i,
            fact_id     = fact.fact_id,
            source_path = fact.source and fact.source.path,
            source_line = fact.source and fact.source.line,
            label       = b and b.label,
            ct          = b and b.ct,
            species     = b and b.species,
            grade       = b and b.grade,
            ingested_at = fact.ingested_at,
        }
    end

    return rows
end

----------------------------------------------------------------
-- Full fact (single row deep dive)
----------------------------------------------------------------

---@param ledger table
---@param index number
---@return table|nil
function Inspect.fact(ledger, index)
    local fact = ledger.facts[index]
    if not fact then return nil end

    return {
        fact_id      = fact.fact_id,
        content_key = short(fact.content_key, 120),
        ingested_at = fact.ingested_at,
        source      = fact.source,
        board       = fact.board,
    }
end

----------------------------------------------------------------
-- Filter helpers
----------------------------------------------------------------

---@param ledger table
---@param path string
---@return table[]
function Inspect.by_source(ledger, path)
    local out = {}

    for _, fact in ipairs(ledger.facts) do
        if fact.source and fact.source.path == path then
            out[#out + 1] = fact
        end
    end

    return out
end

----------------------------------------------------------------
-- Ingestion overview (diff-friendly, ledger-only truth)
----------------------------------------------------------------

---@param ledger table
---@return table
function Inspect.overview(ledger)
    local rows = {}
    local cumulative = 0

    for i, ingest in ipairs(ledger.ingestions or {}) do
        cumulative = cumulative + (ingest.added or 0)

        rows[#rows + 1] = {
            index       = i,
            at          = ingest.at,
            source      = ingest.source and ingest.source.path,
            boards_seen = ingest.boards_seen,
            added       = ingest.added,
            skipped     = ingest.skipped,
            total_facts_after = cumulative,
        }
    end

    return {
        ledger_created_at = ledger.meta and ledger.meta.created_at,
        ledger_version    = ledger.meta and ledger.meta.version,
        total_ingestions  = #rows,
        total_facts       = #ledger.facts,
        ingestions        = rows,
    }
end

return Inspect
