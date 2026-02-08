-- tests/board_invariants_test.lua
--
-- Boards produced by ingestion must be authoritative objects.

local Ingest = require("ingestion.adapter")
local H      = require("tests._helpers")

local path = "tests/data_format/input.txt"

local result = Ingest.ingest(path)
local boards = result.boards.data

for i, board in ipairs(boards) do
    H.assert_table(board, "board #" .. i)

    -- Minimal invariant: dimensions exist
    assert(board.base_h, "board missing base_h")
    assert(board.base_w, "board missing base_w")
    assert(board.l,      "board missing l")
end
