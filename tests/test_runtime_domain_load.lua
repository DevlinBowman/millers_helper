-- tests/runtime/test_runtime_domain_load.lua
--
-- Runtime Domain Load Inspection (Raw Structure)
--
-- Uses inspector to show true underlying data.
--
-- Run:
--   lua tests/runtime/test_runtime_domain_load.lua

local I       = require("inspector")
local Runtime = require("core.domain.runtime").controller

local INPUT_PATH =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input_short.txt"

print("\n================ LOAD =================\n")

local runtime, err = Runtime.load(INPUT_PATH)

print("runtime object:")
I.print(runtime, {shape_only = true})

print("\nerror:")
I.print(err)

assert(runtime, err or "runtime load failed")

print("\n================ RAW RUNTIME =================\n")

-- If raw() exists, use it
if runtime.raw then
    I.print(runtime:raw(), {shape_only = true})
else
    print("runtime.raw() not available")
end

print("\n================ BATCHES =================\n")

local batches = runtime:batches()
I.print(batches, {shape_only = true})

print("\n================ FIRST BATCH =================\n")

local first_batch = runtime:batch()
I.print(first_batch, {shape_only = true})

print("\n================ ORDER =================\n")

local order = runtime:order()
I.print(order, {shape_only = true})

print("\n================ BOARDS (FIRST BATCH) =================\n")

local boards = runtime:boards(1)
I.print(boards, {shape_only = true})

print("\n================ ALL BOARDS =================\n")

local all_boards = runtime:boards()
I.print(all_boards, {shape_only = true})

print("\n================ ORDERS (AGGREGATE) =================\n")

local all_orders = runtime:orders()
I.print(all_orders, {shape_only = true})

print("\n================ DONE =================\n")
