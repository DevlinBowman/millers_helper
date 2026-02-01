local I       = require("inspector")
local Adapter = require("ingestion_v2.adapter")
local Report  = require("ingestion_v2.report")

local Ledger  = require("ledger")
local Store   = Ledger.store
local Ingest  = Ledger.ingest

local INPUT       = "tests/data_format/input.txt"
local LEDGER_PATH = "data/ledger.lua"

local ingest_result = assert(Adapter.ingest(INPUT))

-- Always show a clean summary
Report.print(ingest_result)

-- Boards only
local boards = ingest_result.boards.data

-- Ledger sees boards ONLY
local ledger = Store.load(LEDGER_PATH)
local report = Ingest.run(ledger, boards, {
    source_path = INPUT,
})

I.print(report)
