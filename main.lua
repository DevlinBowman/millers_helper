local I       = require("inspector")
local Backend = require("system.backend")
local Runtime = require('core.domain.runtime').controller

local app     = Backend.run("default")

------------------------------------------------------------
-- Inputs (descriptors only)
------------------------------------------------------------


app:data():submit("job", {
    boards_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input_short.txt",
    order_path  = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
})

app:data():submit("vendor", {
    name = "home depot",
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/home_depot.txt"
})

app:data():submit("job", {
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv",
})
-- app:data():slots():set_selection("user", "job", 12)



-- app:data():submit("vendor", {
--     name = "ace hardware",
--     path = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/ace_ben_lomond.txt"
-- })
--
local tar = app:data():resources():get_one("user", "job", "path")
-- print(tar)
I.print(Runtime.load(tar):batches())

-- app:services():vendor():run()
-- local res = app:services():quote():run():print()
-- local res = app:services():invoice():run():print()
-- app:services():compare():run():print()
-- local committed = app:services():ledger():commit({ force = false })
-- I.print(committed:transactions(), { shape_only = true })
--
-- local all = app:services():ledger():read_all()
-- I.print(all:transactions(), { shape_only = true })
--
-- I.print(app:services():ledger():read_all():transactions())
--
-- local txns = app:services():ledger():read_all():transactions()
-- local id = txns[1] and txns[1].transaction_id
-- I.print(app:services():ledger():read_bundle(id), { shape_only = true })
-- I.print(app:data():inspect() )
