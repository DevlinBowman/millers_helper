-- tests/reader_smoke_test.lua
--
-- Reader must return canonical records for all supported formats.
-- NO board logic. NO validation.

local Reader = require("ingestion_v2.reader")
local H = require("tests._helpers")

local files = {
    "tests/data_format/input.txt",
    "tests/data_format/input2.txt",
    "tests/data_format/test_lumber.txt",
    "tests/data_format/test_lumber.csv",
    "tests/data_format/old_sheet.csv",
    "tests/data_format/test_lumber.json",
}

for _, path in ipairs(files) do
    local ok, records = pcall(Reader.read, path)
    H.assert_ok(ok, records)

    H.assert_kind(records, "records", path)
    H.assert_table(records.data, path .. ".data")
end
