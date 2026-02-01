-- ledger/ingest.lua
--
-- Ingest Boards into the ledger.
-- Idempotent by content_key.

local Identity = require("ledger.identity")

local Ingest = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function gen_fact_id(n)
    return string.format("fact-%06d", n)
end

local function build_seen_index(ledger)
    local seen = {}
    for _, fact in ipairs(ledger.facts) do
        seen[fact.content_key] = true
    end
    return seen
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Ingest boards into ledger
---
--- @param ledger table
--- @param boards { kind:"boards", data:table[] }
--- @param source { path:string }
--- @return table report
function Ingest.run(ledger, boards, source)
    assert(type(ledger) == "table", "ledger required")
    assert(boards.kind == "boards", "expected kind='boards'")
    assert(type(source) == "table" and source.path, "source.path required")

        -- Normalize source contract
    local src = {
        path = source.path or source.source_path,
    }
    assert(src.path, "source.path (or source_path) required")

    local now = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local seen = build_seen_index(ledger)
    local next_id = #ledger.facts + 1

    local report = {
        rows_seen = #boards.data,
        added = 0,
        skipped = 0,
    }

    for i, board in ipairs(boards.data) do
        local key = Identity.compute(board, source)

        if seen[key] then
            report.skipped = report.skipped + 1
        else
            ledger.facts[#ledger.facts + 1] = {
                fact_id     = gen_fact_id(next_id),
                content_key = key,
                board       = board,
                source      = {
                    path = source.path,
                    line = i,
                },
                ingested_at = now,
            }

            seen[key] = true
            report.added = report.added + 1
            next_id = next_id + 1
        end
    end

    ledger.ingestions[#ledger.ingestions + 1] = {
        at = now,
        source = source,
        rows_seen = report.rows_seen,
        added = report.added,
        skipped = report.skipped,
    }

    return report
end

return Ingest
