local I        = require("inspector")
local Backend  = require("system.backend")

local Pricing  = require("core.domain.pricing").controller
local Board    = require("core.model.board").controller

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

------------------------------------------------------------
-- Load vendor runtime data
------------------------------------------------------------

app:data():runtime():pull("system", "vendor")
local vendors = app:data():runtime():batches("system", "vendor")

assert(vendors and #vendors > 0, "no vendor batches found")

-- select first vendor
local vendor = vendors[1]

print("\nUsing Vendor:", vendor.id)

------------------------------------------------------------
-- Load user runtime data
------------------------------------------------------------

app:data():runtime():pull("user")
local jobs = app:data():runtime():batches("user", "job")
local target_batch_idx = 7
local batch  = jobs[target_batch_idx]
local boards = batch.boards

print("\nLoaded boards:", #boards)

------------------------------------------------------------
-- Run vendor_anchor pricing
------------------------------------------------------------

local pricing_result =
    Pricing.run(
        boards,
        "vendor_anchor",
        {
            profile = "default",
            vendor = {
                kind  = "vendor",
                items = vendor.boards,
                meta  = { name = vendor.id }
            },
            percentage = 10
        }
    )

------------------------------------------------------------
-- Inspect pricing model (debug)
------------------------------------------------------------

local pricing_model = pricing_result:model():raw()

assert(type(pricing_model) == "table", "pricing model must be table")

print("\nPricing model snapshot:")
I.print(pricing_model)

------------------------------------------------------------
-- Mutate runtime boards with computed prices
------------------------------------------------------------

local per_board = pricing_model.per_board

assert(type(per_board) == "table", "pricing model missing per_board data")

for i, board in ipairs(boards) do

    local row = per_board[i]

    if row and row.recommended_price_per_bf then
        Board.mutate(board, {
            bf_price = row.recommended_price_per_bf
        })
    end

end

------------------------------------------------------------
-- Inspect updated runtime boards
------------------------------------------------------------

print("\nRuntime boards after mutation:\n")

for _, board in ipairs(boards) do
    print(board.label, board.bf_price, board.ea_price)
end

I.print(app:data():runtime():all('user', 'job')[1].__batches[target_batch_idx].boards)
