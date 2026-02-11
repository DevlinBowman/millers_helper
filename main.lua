-- main.lua
--
local I           = require("inspector")
local Adapter     = require("ingestion.adapter")
local Report      = require("ingestion.report")

local Ledger      = require("core.ledger")

-- local INPUT       = "tests/data_format/old_sheet.csv"
-- local INPUT       = "tests/data_format/input.txt":w
--
local test_inputs = {
    -- '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/input.txt',
    '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/test_lumber.csv',
    -- '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/test_lumber.json',
    -- '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/test_lumber.txt'
}

local IO          = require('io.controller')


for i, file in pairs(test_inputs) do
    print(file)
    -- local data = IO.read(file)
    local data = Adapter.ingest(file)
    I.print(data, {shape_only = true})
end

