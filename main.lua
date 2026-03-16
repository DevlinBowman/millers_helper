local I        = require("inspector")
local Backend  = require("system.backend")
local Executor = require("system.execution.controller")

local app = Backend.run("default")

------------------------------------------------------------
-- Register Resources
------------------------------------------------------------

app:data():submit("vendor", {
    name = "ace_hardware",
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/ace_hardware.csv"
})

app:data():submit("job", {
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv",
})

------------------------------------------------------------
-- Slot Selection
------------------------------------------------------------

-- select job batch
app:data():slots():set_selection("user","job",{ batch = 3})
app:data():slots():set_selection("user","job:pricing",{ batch = 1, board = 2})
app:data():slots():set_selection("user","job:quote",{ batch = 1, board = 2})
-- select vendor batch
-- app:data():slots():set_selection("system", "vendor", 3)
-- app:data():slots():set_selection("system","vendor:compare",1)
app:data():slots():set_selection("system","vendor:pricing",{ batch = 1 })

-- app:data():slots():clear_selection('system', 'vendor')
app:data():slots():clear_selection('user', 'job:quote')

------------------------------------------------------------
-- Load Runtime Batches
------------------------------------------------------------

app:data():runtime():pull("system", "vendor")
app:data():runtime():pull("user", "job")

-- local batch_val = app:data():runtime():require("user", "job"):batch().order.value
-- I.print(batch_val)
-- I.print(app:data():inspect(), {ignore_keys = {'__batches'}})
------------------------------------------------------------
-- Intent Configuration
------------------------------------------------------------

app:data():intent():set("pricing", {
    basis = "vendor_anchor",
    -- vendor = {
    --     scope = "system",
    --     role  = "vendor"
    -- },
    percentage = 15
})
I.print(app:data():slots():resolve("user", "job"))
I.print(app:data():intent():inspect())
-- app:data():intent():clear('pricing')
-- I.print(app:data(), {ignore_keys= '__batches'})


------------------------------------------------------------
-- Baseline Quote (Full Execution)
------------------------------------------------------------

print("\n--- Executor Quote (full system path) ---")

local exec_quote = Executor.run(app, "quote")
I.print(exec_quote)

exec_quote:print()

------------------------------------------------------------
-- Compare (Triggers Enrichment + Pricing)
------------------------------------------------------------

print("\n--- Compare Execution ---")

local compare_result = Executor.run(app, "compare", { force = true })
-- --
compare_result:print()

------------------------------------------------------------
-- Quote After Pricing (Executor Path)
------------------------------------------------------------

print("\n--- Quote After Pricing (executor) ---")


-- Executor.run(app, "pricing")
Executor.run(app, "quote"):print()

------------------------------------------------------------
-- Inspect Application State
------------------------------------------------------------

-- I.print(app, {ignore_keys = {'batch', '__batches'}})
--
-- I.print(app:data():runtime():require('system','vendor'))
--
