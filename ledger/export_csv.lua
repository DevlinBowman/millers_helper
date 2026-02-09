-- ledger/export_csv.lua
--
-- Export ledger facts (BOARD DATA ONLY) to CSV.
--
-- Contract:
--   • One row per ledger.fact
--   • Row source = fact.board
--   • Header = preferred ordered fields + remaining board keys
--   • board.id is ALWAYS the first column
--   • Deterministic, stable output
--
-- NO ingestion logic
-- NO schema inference
-- NO mutation

local IO = require('io')

local Export = {}

----------------------------------------------------------------
-- Preferred column order (prefix)
----------------------------------------------------------------

local PREFERRED_ORDER = {
    "id",
    "date",

    "base_h",
    "base_w",
    "h",
    "w",
    "l",

    "tag",
    "ct",

    "bf_ea",
    "bf_batch",
    "bf_per_lf",
    "bf_price",
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function normalize_cell(v)
    if v == nil then
        return ""
    end
    return tostring(v)
end

local function collect_board_keys(facts)
    local keys = {}

    for _, fact in ipairs(facts) do
        local board = fact.board
        if type(board) == "table" then
            for k in pairs(board) do
                keys[k] = true
            end
        end
    end

    return keys
end

local function build_header(keyset)
    local header = {}
    local used   = {}

    -- 1) Preferred ordered fields (only if present)
    for _, key in ipairs(PREFERRED_ORDER) do
        if keyset[key] then
            header[#header + 1] = key
            used[key] = true
        end
    end

    -- 2) Remaining keys (sorted)
    local rest = {}
    for key in pairs(keyset) do
        if not used[key] then
            rest[#rest + 1] = key
        end
    end

    table.sort(rest)

    for _, key in ipairs(rest) do
        header[#header + 1] = key
    end

    return header
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Write ledger facts to CSV
---
--- @param ledger table
--- @param path string
--- @return boolean ok, string|nil err
function Export.write_csv(ledger, path)
    assert(type(ledger) == "table", "ledger required")
    assert(type(ledger.facts) == "table", "ledger.facts required")
    assert(type(path) == "string", "output path required")

    local facts = ledger.facts

    ----------------------------------------------------------------
    -- 1) Collect board keys (BOARD ONLY)
    ----------------------------------------------------------------
    local keyset = collect_board_keys(facts)
    local header = build_header(keyset)

    ----------------------------------------------------------------
    -- 2) Build rows
    ----------------------------------------------------------------
    local rows = {}

    for _, fact in ipairs(facts) do
        local board = fact.board
        local row = {}

        for _, key in ipairs(header) do
            row[#row + 1] = normalize_cell(board[key])
        end

        rows[#rows + 1] = row
    end

    ----------------------------------------------------------------
    -- 3) Write via IO
    ----------------------------------------------------------------
    local result, err = IO.write(path, "table", {
        header = header,
        rows   = rows,
    })

    if not result then
        return nil, err
    end

    return true
end

return Export
