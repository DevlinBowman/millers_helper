-- ingestion_v2/board_capture.lua
--
-- Responsibility:
--   Load one or more inputs and expose parsed Boards
--   grouped per input source.
--
-- NO ledger logic.
-- NO aggregation by default.
-- NO mutation of Boards.

local Adapter = require("ingestion_v2.adapter")

local Capture = {}

--- Load one or more sources and return a BoardCapture
--- @param paths string|string[]
--- @param opts table|nil
--- @return table board_capture
function Capture.load(paths, opts)
    opts = opts or {}

    if type(paths) == "string" then
        paths = { paths }
    end

    local sources = {}

    local total_boards   = 0
    local total_errors   = 0
    local total_warnings = 0

    for _, path in ipairs(paths) do
        local result = Adapter.ingest(path, opts)

        local source = {
            source_id   = path,
            source_path = path,

            boards = {
                kind = "boards",
                data = result.boards.data or {},
            },

            signals = {
                errors   = result.errors or {},
                warnings = result.warnings or {},
            },

            meta = {
                total_records  = result.meta and result.meta.total_records,
                boards_created = result.meta and result.meta.boards_created,
                error_count    = result.meta and result.meta.error_count,
                warning_count  = result.meta and result.meta.warning_count,
                input_kind     = result.meta and result.meta.input_kind,
            },
        }

        total_boards   = total_boards   + #source.boards.data
        total_errors   = total_errors   + #source.signals.errors
        total_warnings = total_warnings + #source.signals.warnings

        sources[#sources + 1] = source
    end

    return {
        kind = "board_capture",

        sources = sources,

        meta = {
            source_count   = #sources,
            total_boards   = total_boards,
            total_errors   = total_errors,
            total_warnings = total_warnings,
        }
    }
end

return Capture
