-- core/board/serialize.lua
-- Board → tabular serialization (CSV/TSV safe)

local Schema = require("core.board.schema")

---@class BoardSerialize
local Serialize = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function normalize_cell(v)
    if v == nil then
        return ""
    end
    if type(v) == "table" then
        -- JSON-ish fallback for structured fields
        return tostring(v)
    end
    return tostring(v)
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Convert boards into tabular data for file_handler
--- @param boards table[]  -- array of Board
--- @return table { header: string[], rows: string[][] }
function Serialize.boards_to_table(boards)
    assert(type(boards) == "table", "boards_to_table(): boards required")

    ------------------------------------------------------------
    -- 1) Schema columns (authoritative order)
    ------------------------------------------------------------
    local header = {}
    for field in pairs(Schema.fields) do
        header[#header + 1] = field
    end
    table.sort(header) -- stable, predictable (can later be overridden)

    ------------------------------------------------------------
    -- 2) Detect extra fields (lossless ingest)
    --     (exclude derived runtime caches)
    ------------------------------------------------------------
    local extra_fields = {}

    for _, board in ipairs(boards) do
        for k in pairs(board) do
            if not Schema.fields[k]
                and k ~= "bf_ea"
                and k ~= "bf_per_lf"
            then
                extra_fields[k] = true
            end
        end
    end

    local extra = {}
    for k in pairs(extra_fields) do
        extra[#extra + 1] = k
    end
    table.sort(extra)

    ------------------------------------------------------------
    -- 3) Final header
    ------------------------------------------------------------
    for _, k in ipairs(extra) do
        header[#header + 1] = k
    end

    ------------------------------------------------------------
    -- 4) Rows
    ------------------------------------------------------------
    local rows = {}

    for _, board in ipairs(boards) do
        local row = {}
        for _, key in ipairs(header) do
            row[#row + 1] = normalize_cell(board[key])
        end
        rows[#rows + 1] = row
    end

    return {
        header = header,
        rows   = rows,
    }
end

return Serialize
