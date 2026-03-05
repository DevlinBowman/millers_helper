local I        = require("inspector")
local Backend  = require("system.backend")

local Runtime  = require("core.domain.runtime").controller
local Pricing  = require("core.domain.pricing").controller
local Format   = require("core.model.pricing.internal.format")

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

-- Specify Vendor Data
-- load resource into Runtime
app:data():runtime():pull("system", 'vendor')
-- collect list of vendor batchs from runtime
local ven_data = app:data():runtime():batches('system', 'vendor')
-- I.print(ven_data)


-- Specify User Data
-- load resource into runtime
app:data():runtime():pull('user')
local usr_data = app:data():runtime():batches('user', 'job')


local batch  = usr_data[14]
local boards = batch.boards

print("\nLoaded boards:", #boards)
------------------------------------------------------------
-- Run vendor_anchor pricing against each vendor
------------------------------------------------------------

for _, vendor in ipairs(ven_data) do

    print("\n==========================================")
    print("Vendor Pricing Check:", vendor)
    print("==========================================")

    local pricing_result =
        Pricing.run( boards, "vendor_anchor", {
                profile = "default",
                vendor = {
                    kind  = "vendor",
                    items = vendor.boards,
                    meta  = { name = vendor.id }
                },
                percentage = 10
            }
        )

    local formatted =
        Format.result(pricing_result:model():raw())

    print(formatted)

end

------------------------------------------------------------
-- Optional: run hybrid_market check
------------------------------------------------------------

-- local cost_surface = {
--     cost_per_bf = 3.25
-- }
--
-- local hybrid_result =
--     Pricing.run(
--         boards,
--         "hybrid_market",
--         {
--             profile = "default",
--
--             compare = {
--                 kind = "compare",
--                 model = nil
--             },
--
--             opts = {
--                 cost_surface = cost_surface,
--                 waste_ratio = 0.05,
--                 rush_level = 0,
--                 market_target_discount = 15
--             }
--         }
--     )
--
-- print("\n==========================================")
-- print("Hybrid Market Pricing")
-- print("==========================================")
--
-- print(
--     Format.result(
--         hybrid_result:model():raw()
--     )
-- )
