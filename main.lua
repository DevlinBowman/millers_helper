print('running main.lua')
local I           = require("inspector")
local Trace       = require("tools.trace.trace")
local Ingest      = require("pipelines.ingestion.ingest")
local Bundle = require('pipelines.ingestion.context_bundle')
local Export      = require("pipelines.export.export")

local Ledger      = require("core.domain.ledger.controller")
local Printer = require("core.domain.ledger.internal.analytics_printer")

local Diagnostic  = require("tools.diagnostic")
local ConsoleSink = require("tools.diagnostic.sinks.console")

local Load = require("core.domain.runtime.pipelines.load")

-- Diagnostic.add_sink(ConsoleSink.new({
--     print_debug = true,
--     min_signal_severity = "info",
-- }))

-- Trace.set(true)
Trace.set_mode("collapse")
Trace.set_shape_mode("runtime")
Trace.set_shape_depth(2)

-- local boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input_short.txt"
-- local order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
-- local all_current = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"
-- local tlcsv       = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/test_lumber.csv"


local boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt"
local order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
local all_current = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"
local tlcsv       = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/test_lumber.csv"

-- --
-- -- local PathMap = require("tools.struct.path_map")
-- --
-- -- local result = Ingest.read(boards_path)
-- -- PathMap.print(result)
-- --
-- -- local bundle = Bundle.load(order_path, boards_path)
-- -- PathMap.print(bundle)
-- --
-- -- local ledger = Ledger.read_all_full()
-- -- PathMap.print(ledger)
-- -- --
--
-- local Struct = require('tools.struct')
-- Struct.print_all()
--
local data = Load.run(boards_path)
I.print(data)
