local I       = require("inspector")
local Backend = require("system.backend")
local S       = require('core.schema')



------------------------------------------------------------
-- Boot Backend
------------------------------------------------------------

local app = Backend.run("default")

------------------------------------------------------------
-- Inputs
------------------------------------------------------------

app:data():submit("job", {
    boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input_short.txt",
    order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
})

app:data():submit("job", {
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"
})

app:data():runtime():pull("system", "vendor")
local vendors = app:data():runtime():batches("system", "vendor")

app:data():runtime():pull("user")
local job = app:data():runtime():batches("user", "job")[8]
I.print(job)


local result = S.object.audit("batch", job):capabilities()

I.print(result)
