local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")
local FromLines = require("ingestion.normalization.from_lines")

local BoardRec  = require("ingestion.normalization.reconcile_board")
local Hydrate   = require("ingestion.hydrate.board")

local Pipeline = {}

function Pipeline.run_file(path, cfg)
    cfg = cfg or {}

    -- READ
    local raw, err = Read.read(path)
    if not raw then return nil, err end

    local records

    -- ----------------------------
    -- TEXT INPUT (raw lines)
    -- ----------------------------
    if raw.kind == "lines" then
        -- TEMP: verification-only parser
        records = FromLines.run(raw)

        -- IMPORTANT:
        -- stop here until a real text→board parser exists
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

    records.meta = raw.meta

    -- ----------------------------
    -- RECONCILE → BOARD SPECS
    -- ----------------------------
    local board_specs = BoardRec.run(records)

    -- ----------------------------
    -- HYDRATE → BOARDS
    -- ----------------------------
    return Hydrate.boards(board_specs), nil
end

return Pipeline
