-- ledger/ingest.lua
--
-- Ingest sparse normalized records into the ledger.

local Identity = require("ledger.identity")

local Ingest = {}

local function gen_ingestion_id()
    return os.date("!%Y-%m-%dT%H:%M:%SZ") .. "-" .. tostring(math.random(1000, 9999))
end

local function gen_fact_id(n)
    return string.format("fact-%06d", n)
end

local function build_seen_set(ledger)
    local seen = {}
    for _, f in ipairs(ledger.facts) do
        seen[f.content_key] = true
    end
    return seen
end

---@param ledger table
---@param records { kind:"records", data:table[], meta:table }
---@param source table|nil
---@return table report
function Ingest.run(ledger, records, source)
    assert(records.kind == "records", "expected kind='records'")

    local ingestion_id = gen_ingestion_id()
    local now = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local seen = build_seen_set(ledger)
    local next_id = #ledger.facts + 1

    local report = {
        ingestion_id = ingestion_id,
        rows_seen = #records.data,
        added = 0,
        skipped = 0,
    }

    for i, rec in ipairs(records.data) do
        local key = Identity.compute(rec)

        if seen[key] then
            report.skipped = report.skipped + 1
        else
            ledger.facts[#ledger.facts + 1] = {
                fact_id      = gen_fact_id(next_id),
                ingestion_id = ingestion_id,
                content_key  = key,
                data         = rec,
                source       = {
                    input = records.meta and records.meta.input,
                    line  = i,
                    extra = source,
                },
                ingested_at  = now,
            }

            seen[key] = true
            report.added = report.added + 1
            next_id = next_id + 1
        end
    end

    ledger.ingestions[ingestion_id] = {
        started_at  = now,
        completed_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        rows_seen   = report.rows_seen,
        added       = report.added,
        skipped     = report.skipped,
        source      = source,
    }

    return report
end

return Ingest
