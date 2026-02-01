-- ingestion/pipeline.lua
--
-- Purpose:
--   Read a file and normalize it into canonical "records".
--   This module does NOT hydrate boards and does NOT return mixed kinds.
--   The adapter is the contract gate for boards.

local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")
local FromLines = require("ingestion.normalization.from_lines")

local Pipeline  = {}

---@param path string
---@param opts table|nil
---@param debug_opts table|nil
---@return { kind: "records", data: table[], meta: table }|nil
---@return string|nil
function Pipeline.run_file(path, opts, debug_opts)
    opts = opts or {}
    debug_opts = debug_opts or {}

    -- READ (raw file -> {kind=...})
    local raw, err = Read.read(path)
    if not raw then
        return nil, err
    end

    local records

    -- ----------------------------
    -- TEXT INPUT (raw lines)
    -- ----------------------------
    if raw.kind == "lines" then
        records = FromLines.run(raw, {
            capture = debug_opts.capture,
        })

        -- Preserve file meta on the records meta object
        records.meta = records.meta or {}
        records.meta.file = raw.meta
        records.meta.source_path = path

        return records, nil
    end

    -- ----------------------------
    -- TABULAR / JSON INPUT
    -- ----------------------------
    if raw.kind == "table" then
        records = Normalize.table(raw)

    elseif raw.kind == "json" then
        records = assert(Normalize.json(raw))

    else
        return nil, "unsupported input kind: " .. tostring(raw.kind)
    end

    -- Normalize.* should yield {kind="records", data=..., meta=...} in your system.
    assert(type(records) == "table" and records.kind == "records", "Normalize must return kind='records'")

    records.meta = records.meta or {}
    records.meta.file = raw.meta
    records.meta.source_path = path

    return records, nil
end

return Pipeline
