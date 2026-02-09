-- tests/parser_survival_test.lua
--
-- Parser must not crash on any known text input.

local Read       = require("io.read")
local TextParser = require("parsers.text_pipeline")
local H          = require("tests._helpers")

local files = {
    "tests/data_format/input.txt",
    "tests/data_format/input2.txt",
    "tests/data_format/test_lumber.txt",
}

for _, path in ipairs(files) do
    local raw = assert(Read.read(path))
    assert(raw.kind == "lines", path .. " expected line input")

    local ok, records = pcall(TextParser.run, raw.data)
    H.assert_ok(ok, records)
    H.assert_kind(records, "records", path)
end
