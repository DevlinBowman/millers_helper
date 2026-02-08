-- tests/ingest_signals_test.lua
--
-- Signals must be structured and index-addressable.

local Ingest = require("ingestion.adapter")
local H      = require("tests._helpers")

local path = "tests/data_format/input.txt"
local result = Ingest.ingest(path)

for _, err in ipairs(result.signals.errors) do
    assert(err.index, "error missing index")
    assert(err.code,  "error missing code")
end

for _, warn in ipairs(result.signals.warnings) do
    assert(warn.index, "warning missing index")
    assert(warn.code,  "warning missing code")
end
