-- tests/parser_multi_input_test.lua
--
-- Parser must never crash on line-based inputs.
-- No semantic expectations.

local Read       = require("file_handler")
local TextParser = require("parsers.text_pipeline")
local H          = require("tests._helpers")

local files = {
    "tests/data_format/input.txt",
    "tests/data_format/input2.txt",
    "tests/data_format/test_lumber.txt",
}

for _, path in ipairs(files) do
    local raw = assert(Read.read(path))
    assert(raw.kind == "lines", path .. " expected lines")

    local ok, records = pcall(TextParser.run, raw.data)
    H.assert_ok(ok, records)
    H.assert_kind(records, "records", path)
end
