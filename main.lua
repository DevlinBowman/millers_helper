-- main.lua
--
-- Application entry point
-- Normal execution stays clean.
-- Inspection is one-line, module-targeted, and disposable.

local I       = require("inspector")
local View    = require("debug.view")
local Adapter = require("ingestion.adapter.readfile")

local INPUT = "tests/data_format/input.txt"

----------------------------------------------------------------

local boards = assert(Adapter.ingest(INPUT))
I.print(boards)
