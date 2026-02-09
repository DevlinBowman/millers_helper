-- ingestion/reader.lua
--
-- Responsibility:
--   Read a file and return raw structured data.
--   NO validation
--   NO board logic
--   NO format-specific branching outside IO contract

local Read = require("io.read")
local Normalize  = require("io.normalize")
local TextParser = require("parsers.text_pipeline")

local Reader = {}

---@param path string
---@param opts table|nil
---@return { kind: "records", data: table[], meta: table }
function Reader.read(path, opts)
    opts = opts or {}

    -- IO boundary (format-agnostic)
    local raw, err = Read.read(path)
    assert(raw, err)

    local records

    if raw.kind == "lines" then
        -- freeform text → parser-owned normalization
        records = TextParser.run(raw.data, opts)

    elseif raw.kind == "table" then
        -- structured tabular → records
        records = Normalize.table(raw)

    elseif raw.kind == "json" then
        -- structured json → records
        local norm, nerr = Normalize.json(raw)
        assert(norm, nerr)
        records = norm

    else
        error("unsupported input kind: " .. tostring(raw.kind))
    end

    assert(records.kind == "records", "reader must return kind='records'")

    -- ingestion-owned metadata enrichment
    records.meta = records.meta or {}
    records.meta.source_path = path
    records.meta.input_kind  = raw.kind

    return records
end

return Reader
