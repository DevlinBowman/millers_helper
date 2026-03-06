-- core/domain/enrichment/dev/test.lua

local I       = require("inspector")
local Backend = require("system.backend")
local Engine  = require("core.domain.enrichment.engine")

------------------------------------------------
-- Boot app
------------------------------------------------

local app = Backend.run("default")

------------------------------------------------
-- Load job data
------------------------------------------------

app:data():submit("job", {
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"
})

app:data():runtime():pull("system", "vendor")
app:data():runtime():pull("user")

local batch_idx = 12
local vendor = app:data():runtime():batches("system", "vendor")[1]
local batch  = app:data():runtime():batches("user", "job")[batch_idx]
I.print(batch)

print("\nSelected batch:", batch_idx, "\n")

local vendor_env = {
    kind  = "vendor",
    items = vendor.boards,
    meta  = {
        name = vendor.id
    }
}
------------------------------------------------
-- Execute enrichment
------------------------------------------------

local result = Engine.execute("batch", batch, {
    pricing_basis = "vendor_anchor",
    profile = "default",
    vendor = vendor_env,
    percentage = 10
})

-- local result = Engine.execute("batch", batch, {
--     pricing_basis = "reverse_order_value",
--     profile = "default"
-- })

------------------------------------------------
-- Inspect orchestration artifacts
------------------------------------------------

-- print("\nRequests:\n")
-- I.print(result.requests)
--
-- print("\nTasks:\n")
-- I.print(result.tasks)
--
-- print("\nPatches:\n")
-- I.print(result.patches)
--
-- print("\nSkipped:\n")
-- I.print(result.skipped)

------------------------------------------------
-- Inspect mutated runtime batch
------------------------------------------------

print("\nMutated runtime boards:\n")

for i, board in ipairs(batch.boards) do
    print(
        i,
        board.label,
        "bf:", board.bf_price,
        "ea:", board.ea_price,
        "lf:", board.lf_price
    )
end

print("\nFull runtime batch snapshot:\n")
-- I.print(batch)
--
-- print("\nCapabilities after enrichment:\n")
-- I.print(Engine.run("batch", batch).capabilities)
