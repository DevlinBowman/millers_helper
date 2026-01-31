local Capture = require("parsers.text_pipeline.capture")
local I       = require("inspector")
local Adapter = require("ingestion.adapter.readfile")

local cap = Capture.new()

local boards = assert(Adapter.ingest(
    "tests/data_format/input.txt",
    {},
    { capture = cap }
))

-- ingestion result (unchanged)
I.print(boards)

-- FULL parser state for line 1
I.print(cap.lines[1])
