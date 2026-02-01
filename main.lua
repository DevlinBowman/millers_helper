-- main.lua
--
-- Canonical CLI entrypoint

local cli = require("cli")

local ok, err = pcall(cli.run, { ... })
if not ok then
    io.stderr:write("error: " .. tostring(err) .. "\n")
    os.exit(1)
end

-- -- main.lua
-- --
-- local I       = require("inspector")
-- local Adapter = require("ingestion_v2.adapter")
-- local Report  = require("ingestion_v2.report")
--
-- local Ledger  = require("ledger")
-- local Store   = Ledger.store
-- local Ingest  = Ledger.ingest
--
-- -- local INPUT       = "tests/data_format/old_sheet.csv"
-- -- local INPUT       = "tests/data_format/input.txt"
-- local INPUT       = "tests/data_format/test_lumber.json"
-- local LEDGER_PATH = "data/ledger.lua"
--
-- local ingest_result = assert(Adapter.ingest(INPUT))
--
-- -- Always show a clean summary
-- Report.print(ingest_result)
--
-- -- Boards only (authoritative payload)
-- local boards = ingest_result.boards.data
--
-- -- Ledger sees BOARDS ONLY
-- local ledger = Store.load(LEDGER_PATH)
-- local report = Ingest.run(
--     ledger,
--     { kind = "boards", data = boards },
--     { path = INPUT }
-- )
--
-- Store.save(LEDGER_PATH, ledger)
--
-- I.print(report)
--
-- -- High-level
-- -- I.print(Ledger.inspect.summary(ledger))
--
-- -- Spreadsheet-like view
-- -- I.print(Ledger.inspect.list_facts(ledger))
--
-- -- Drill into one fact
-- -- I.print(Ledger.inspect.fact(ledger, 1))
--
-- -- Filter by source file
-- -- I.print(Ledger.inspect.by_source(ledger, "tests/data_format/input.txt"))
-- --
-- -- I.print(Ledger.inspect.overview(ledger))
-- --
-- local Export = require("ledger.export_csv")
--
-- local ok, err = Export.write_csv(ledger, "data/ledger_export.csv")
--
-- assert(ok, err)
--
--

