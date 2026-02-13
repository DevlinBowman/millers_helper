local I = require('inspector')

local IO = require('io.controller')
local Format = require('format.controller')

local Trace = require('tools.trace')
Trace.set(true)

-- 1. Read raw codec envelope
local raw = IO.read('/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/test_lumber.json')
print('raw')
-- I.print(raw, { shape_only = true })

-- 2. Decode to canonical objects
--
local decoded = Format.decode(raw.codec, raw.data)
I.print(decoded, { shape_only = true })

-- 3. Encode objects to target codec
local encoded = Format.encode("lua", decoded.data)
I.print(encoded, { shape_only = true })

-- 4. Write codec envelope
local out = IO.write('data/out/json_to_lua.lua', encoded)
I.print(out)
