-- ledger/ingest.lua
--
-- Ingest Boards into the ledger.
-- Idempotent by content_key.
--
-- IDENTITY MODEL:
--   base_identity = Identity.compute(board, { path })
--   content_key   = base_identity .. "#occ=" .. local_occurrence
--
-- Occurrence numbering:
--   • scoped to THIS read only
--   • resets every ingest
--   • identical boards in same file are distinct
--   • removal never deletes facts
--
-- Ledger only sees:
--   • boards.data
--   • #boards.data

local Identity = require("core.ledger.internal.model.identity")

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

local function basename(path)
    if type(path) ~= "string" then return nil end
    return path:match("([^/\\]+)$") or path
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Ingest boards into ledger
---
--- @param ledger table
--- @param boards { kind:"boards", data:table[] }
--- @param source { path?:string, source_path?:string }
--- @return table report
function Ingest.run(ledger, boards, source)
    assert(type(ledger) == "table", "ledger required")
    assert(type(boards) == "table" and boards.kind == "boards", "expected kind='boards'")
    assert(type(source) == "table", "source table required")

    local src = {
        path = source.path or source.source_path,
    }
    assert(type(src.path) == "string", "source.path (or source_path) required")

    local now        = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local seen       = build_seen_index(ledger)
    local next_id    = #ledger.facts + 1
    local occ_counts = {} -- base_identity -> local occurrence count

    local report     = {
        boards_seen = #boards.data,
        added       = 0,
        skipped     = 0,
    }

    for i, board in ipairs(boards.data) do
        -- 1) Base identity (stable across reads)
        local base_key = Identity.compute(board, { path = src.path })

        -- 2) Local occurrence (per-read only)
        local n = (occ_counts[base_key] or 0) + 1
        occ_counts[base_key] = n

        -- 3) Final identity
        local content_key = base_key .. "#occ=" .. n

        -- 4) Ledger dedupe
        if seen[content_key] then
            report.skipped = report.skipped + 1
        else
            -- Materialize source filename onto the board fact
            if board.source_file == nil then
                board.source_file = basename(src.path)
            end

            ledger.facts[#ledger.facts + 1] = {
                fact_id     = gen_fact_id(next_id),
                content_key = content_key,
                board       = board,
                source      = {
                    path = src.path,
                    line = i, -- provenance only
                },
                ingested_at = now,
            }

            seen[content_key] = true
            report.added = report.added + 1
            next_id = next_id + 1
        end
    end

    ledger.ingestions[#ledger.ingestions + 1] = {
        at          = now,
        source      = { path = src.path },
        boards_seen = report.boards_seen,
        added       = report.added,
        skipped     = report.skipped,
    }

    return report
end

return Ingest
