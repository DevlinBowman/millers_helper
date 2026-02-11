-- main.lua
--
local I           = require("inspector")
local test_inputs = {
    -- '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/input.txt',
    '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/test_lumber.csv',
    -- '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/test_lumber.json',
    -- '/Users/ven/Desktop/2026-lumber-app-v2/data/test_inputs/test_lumber.txt'
}

local IO = require("application.runtime.io")

local result = IO.read_strict("data/test_inputs/test_lumber.json")
I.print(result, {shape_only = true})


