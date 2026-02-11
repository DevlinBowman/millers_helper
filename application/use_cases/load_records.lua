-- application/use_cases/load_records.lua
--
-- Use-case: Load file and project into records.
--
-- Composition:
--   IO → Format
--
-- No domain knowledge.
-- No board logic.
-- No ledger logic.

local IO     = require("application.runtime.io")
local Format = require("application.runtime.format")

local LoadRecords = {}

----------------------------------------------------------------
-- RELAXED
----------------------------------------------------------------

---@param path string
---@return table|nil result
---@return string|nil err
function LoadRecords.run(path)
    local raw, err = IO.read(path)
    if not raw then
        return nil, err
    end

    local records, ferr = Format.to_records(raw.kind, raw.data)
    if not records then
        return nil, ferr
    end

    return records
end

----------------------------------------------------------------
-- STRICT
----------------------------------------------------------------

function LoadRecords.run_strict(path)
    local result, err = LoadRecords.run(path)
    if not result then
        error(err, 2)
    end
    return result
end

return LoadRecords
