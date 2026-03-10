local I       = require("inspector")
local Backend = require("system.backend")
local Runtime = require('core.domain.runtime').controller

local app     = Backend.run("default")

------------------------------------------------------------
-- Inputs (descriptors only)
------------------------------------------------------------




-- app:data():submit("job", {
--     boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/nat_ret.txt",
--     order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
-- })
--
-- app:data():submit("job", {
--     boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/nat_more.txt",
--     order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
-- })

app:data():submit("vendor", {
    name = "ace_hardware",
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/ace_hardware.csv"
})

app:data():submit("job", {
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv",
})
-- app:data():slots():set_selection("user", "job", 12)
--
-- app:services():vendor():run()

------------------------------------------------------------
-- Load runtime batches
------------------------------------------------------------

app:data():runtime():pull("system", "vendor")
app:data():runtime():pull("user", "job")

local job_batches = app:data():runtime():batches("user", "job")
local batch = job_batches[1]
-- I.print(batch)

local vendor_batches = app:data():runtime():batches("system", "vendor")
local vendor = vendor_batches[1]
-- I.print(vendor_batches[2])

------------------------------------------------------------
-- Intent configuration
------------------------------------------------------------

app:data():intent():set("pricing", {
    basis = "reverse_order_value",
    vendor = {}
    --     kind  = "vendor",
    --     items = vendor.boards,
    --     meta  = { name = vendor.id }
    -- },
    -- percentage = 10
})
I.print(app:data():intent():inspect())

------------------------------------------------------------
-- Enrichment (derive missing capabilities such as pricing)
------------------------------------------------------------

local Runner = require("system.app.services.enrichment_runner")

-- local enrichment_result = Runner.run(
--     "batch",
--     batch,
--     app:data():intent():all()
-- )


------------------------------------------------------------
-- Optional: inspect runtime after enrichment
------------------------------------------------------------

-- for i, board in ipairs(batch.boards) do
--     print(
--         i,
--         board.label,
--         "bf:", board.bf_price,
--         "ea:", board.ea_price,
--         "lf:", board.lf_price
--     )
-- end

------------------------------------------------------------
-- Additional vendor (optional)
------------------------------------------------------------

-- app:data():submit("vendor", {
--     name = "ace hardware",
--     path = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/ace_ben_lomond.txt"
-- })

------------------------------------------------------------
-- Services
------------------------------------------------------------

-- app:services():vendor():run()
-- app:services():quote():run():print()
-- app:services():invoice():run():print()

------------------------------------------------------------
-- Compare (now runtime should contain derived prices)
------------------------------------------------------------

local result = app:services():compare():run()

if result and result.print then
    result:print()
else
    print("COMPARE FAILED")
    require("inspector").print(result)
end

I.print(batch)
