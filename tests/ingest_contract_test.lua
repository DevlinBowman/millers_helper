-- tests/ingest_contract_test.lua
--
-- Ingestion V2 contract test.
-- Ensures boards + signals always returned.

local Ingest = require("ingestion_v2.adapter")
local H      = require("tests._helpers")

local files = {
    "tests/data_format/input.txt",
    "tests/data_format/input2.txt",
    "tests/data_format/test_lumber.txt",
    "tests/data_format/test_lumber.csv",
    "tests/data_format/old_sheet.csv",
    "tests/data_format/test_lumber.json",
}

for _, path in ipairs(files) do
    local ok, result = pcall(Ingest.ingest, path)
    H.assert_ok(ok, result)

    H.assert_kind(result, "ingest_result", path)
    H.assert_kind(result.boards, "boards", path .. ".boards")

    -- Signals must exist even if empty
    H.assert_table(result.signals, path .. ".signals")
    H.assert_table(result.signals.errors)
    H.assert_table(result.signals.warnings)
end
