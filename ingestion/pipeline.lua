-- ingestion/pipeline.lua

local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")

local BoardRec  = require("ingestion.normalization.reconcile_board")
local Hydrate   = require("ingestion.hydrate.board")

local Pipeline = {}

function Pipeline.run_file(path, cfg)
    cfg = cfg or {}

    -- READ
    local raw, err = Read.read(path)
    if not raw then return nil, err end

    -- NORMALIZE
    local records = raw
    if raw.kind == "table" then
        records = Normalize.table(raw)
    elseif raw.kind == "json" then
        records = assert(Normalize.json(raw))
    end

    records.meta = raw.meta

    -- RECONCILE → BOARD SPECS
    local board_specs = BoardRec.run(records)

    -- HYDRATE → BOARDS
    local boards = Hydrate.boards(board_specs)

    return boards, nil
end

return Pipeline
