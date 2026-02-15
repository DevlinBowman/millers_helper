local I       = require("inspector")
local Ingest  = require("pipelines.ingestion.ingest")

local boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt"
local order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"

----------------------------------------------------------------
-- Utility
----------------------------------------------------------------

local function run_parser_test(path)

    print("\n=================================================")
    print("PARSER TEST:", path)
    print("=================================================\n")

    ------------------------------------------------------------
    -- INGEST (STOP AT PARSER STAGE)
    ------------------------------------------------------------

    local result, err = Ingest.read(path, {
        -- stop_at = "parser"
    })

    if not result then
        print("\nPARSER GATE ERROR:")
        I.print(err)
        return
    end

    -- print("\n-- PARSER OUTPUT (STOPPED AT CLASSIFY) --")
    I.print(result, { shape_only = true })
end

----------------------------------------------------------------
-- Run Tests
----------------------------------------------------------------

run_parser_test(boards_path)
run_parser_test(order_path)
