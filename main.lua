local I = require('inspector')

local IO = require('io.controller')
local Format = require('format.controller')

local Trace = require('tools.trace')
Trace.set(true)

local data = IO.read('/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/old_sheet.csv')
-- I.print(data, {shape_only = true})

data = Format.convert(data, 'lines')

I.print(data)
local out = IO.write('data/out/csv_to_txt.txt', data)
I.print(out)

