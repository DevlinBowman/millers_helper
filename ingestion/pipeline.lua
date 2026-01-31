local Read      = require("file_handler")
local Normalize = require("file_handler.normalize")
local FromLines = require("ingestion.normalization.from_lines")

local BoardRec  = require("ingestion.normalization.reconcile_board")
local Hydrate   = require("ingestion.hydrate.board")

local Pipeline  = {}

function Pipeline.run_file(path, opts, debug_opts)
    opts = opts or {}
    debug_opts = debug_opts or {}

    -- READ
    local raw, err = Read.read(path)
    if not raw then return nil, err end

    local records

    -- ----------------------------
    -- TEXT INPUT (raw lines)
    -- ----------------------------
    if raw.kind == "lines" then
        -- run text parser (capture may be attached)
        records = FromLines.run(raw, {
            capture = debug_opts.capture
        })

        -- ------------------------------------------------------------
        -- NORMAL MODE: filter + hydrate
        -- ------------------------------------------------------------
        local filtered = {
            kind = "records",
            data = {},
            meta = records.meta,
        }

        for _, rec in ipairs(records.data) do
            if rec.base_h and rec.base_w and rec.l then
                filtered.data[#filtered.data + 1] = rec
            end
        end

        -- nothing valid to hydrate
        if #filtered.data == 0 then
            return records, nil
        end

        local board_specs = BoardRec.run(filtered)
        return Hydrate.boards(board_specs), nil
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
