----------------------------------------------------------------
-- RUNTIME TRAVERSAL TEST (MANUAL)
----------------------------------------------------------------

local I       = require("inspector")
local Trace   = require("tools.trace.trace")
local Runtime = require("core.domain.runtime.controller")

Trace.set_mode("collapse")
Trace.set_shape_mode("runtime")
Trace.set_shape_depth(1)

----------------------------------------------------------------
-- Paths
----------------------------------------------------------------

local boards_and_order_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input_short.txt"
local order_only_path       = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"
local boards_only_path      = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt"
local compiled_orders       = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"
local home_depot            = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/home_depot.txt"
local ace_hardware          = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/ace_ben_lomond.txt"

----------------------------------------------------------------
-- Helper: Inspect RuntimeView
----------------------------------------------------------------

local function inspect_runtime(label, state)
    print("\n==============================")
    print("TEST:", label)
    print("==============================")

    I.print(state, { shape_only = true })

    local batches = state:batches()
    print("batch_count:", #batches)

    if #batches > 0 then
        local first_batch = state:batch(1)
        print("boards in batch[1]:", #first_batch.boards)

        local first_order = state:order(1)
        print("order table exists:", type(first_order) == "table")

        local boards = state:boards(1)
        print("boards accessor works:", type(boards) == "table")

        local all_boards = state:boards()
        print("flattened board count:", #all_boards)
    end

    print("✓ traversable:", label)
end

--------------------------------------------------------------
-- 1. Boards + Order
----------------------------------------------------------------

local state_boards_and_order = Runtime.load(
    boards_and_order_path,
    { name = "boards_and_order", category = "test_input" }
)

inspect_runtime("boards_and_order", state_boards_and_order)

----------------------------------------------------------------
-- 2. Order Only
----------------------------------------------------------------

local state_order_only = Runtime.load(
    order_only_path,
    { name = "order_only", category = "test_input" }
)

inspect_runtime("order_only", state_order_only)

----------------------------------------------------------------
-- 3. Boards Only
----------------------------------------------------------------

local state_boards_only = Runtime.load(
    boards_only_path,
    { name = "boards_only", category = "test_input" }
)

inspect_runtime("boards_only", state_boards_only)

----------------------------------------------------------------
-- 4. Compiled Orders
----------------------------------------------------------------

local state_compiled = Runtime.load(
    compiled_orders,
    { name = "compiled_orders", category = "test_input" }
)

inspect_runtime("compiled_orders", state_compiled)

----------------------------------------------------------------
-- 5. Vendor: Home Depot
----------------------------------------------------------------

local state_home_depot = Runtime.load(
    home_depot,
    { name = "home_depot", category = "vendor" }
)

inspect_runtime("home_depot", state_home_depot)

----------------------------------------------------------------
-- 6. Vendor: Ace Hardware
----------------------------------------------------------------

local state_ace = Runtime.load(
    ace_hardware,
    { name = "ace_hardware", category = "vendor" }
)

inspect_runtime("ace_hardware", state_ace)

----------------------------------------------------------------
-- 7. Grouped Input (Boards + Order)
----------------------------------------------------------------

local grouped_input = {
    boards_path = boards_only_path,
    order_path  = order_only_path
}

local state_grouped = Runtime.load(
    grouped_input,
    { name = "grouped", category = "combined" }
)

inspect_runtime("grouped_input", state_grouped)

print("\nALL MANUAL RUNTIME TESTS COMPLETE")
