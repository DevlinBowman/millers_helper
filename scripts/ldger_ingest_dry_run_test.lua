----------------------------------------------------------------
-- ORDER + BOARD ASSOCIATION TEST (RUNTIME PIPELINE)
----------------------------------------------------------------

local Runtime = require("core.domain.runtime.controller")
local I       = require("inspector")

----------------------------------------------------------------
-- Paths
----------------------------------------------------------------

local order_only_path =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"

local boards_only_path =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt"

----------------------------------------------------------------
-- Load Runtime States
----------------------------------------------------------------

local order_state = Runtime.load(
    order_only_path,
    { name = "order_only", category = "order" }
)

local boards_state = Runtime.load(
    boards_only_path,
    { name = "boards_only", category = "boards" }
)

print("\n--- ORDER STATE ---")
I.print(order_state, { shape_only = true })

print("\n--- BOARDS STATE ---")
I.print(boards_state, { shape_only = true })

-- Execute Association (Using Runtime Layer)
----------------------------------------------------------------

local associated_state = Runtime.associate(
    order_state,
    boards_state,
    {
        name     = "associated_cli",
        category = "order",
        strategy = "attach_all"
    }
)

print("\n--- ASSOCIATED STATE ---")
I.print(associated_state, { shape_only = true })

----------------------------------------------------------------
-- Structural Validation
----------------------------------------------------------------

local batches = associated_state:batches()

assert(#batches == 1, "Expected single associated batch")

local batch = associated_state:batch(1)

assert(type(batch.order) == "table", "Missing order table")
assert(type(batch.boards) == "table", "Missing boards table")

print("\nAssociated board count:", #batch.boards)

----------------------------------------------------------------
-- Provenance Check
----------------------------------------------------------------

if batch.meta and batch.meta.io then
    print("Provenance preserved:")
    print("  source_path:", batch.meta.io.source_path)
    print("  hash:", batch.meta.io.hash)
else
    print("WARNING: No IO provenance found on associated batch")
end

----------------------------------------------------------------
-- Original States Remain Unchanged
----------------------------------------------------------------

print("\nOriginal order boards:", #order_state:boards())
print("Original boards-only boards:", #boards_state:boards())

print("\nASSOCIATION TEST COMPLETE")


local state = Runtime.load(order_only_path, { name="order_only", category="order" })
local b = state:batch(1)
print(b.meta and b.meta.io and b.meta.io.source_path)
