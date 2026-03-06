-- core/domain/enrichment/dev/test.lua

local I       = require("inspector")
local Backend = require("system.backend")
local Schema  = require("core.schema")

local Engine  = require("core.domain.enrichment.engine")

------------------------------------------------
-- Boot app
------------------------------------------------

local app     = Backend.run("default")

------------------------------------------------
-- Load job data
------------------------------------------------

app:data():submit("job", {
    path = "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"
})

app:data():runtime():pull("system", "vendor")
app:data():runtime():pull("user")


local batch_idx = 8
local vendor = app:data():runtime():batches("system", "vendor")[1]
local batch  = app:data():runtime():batches("user", "job")[batch_idx]

print("\nSelected batch:", batch_idx, "\n")

------------------------------------------------
-- Run enrichment engine
------------------------------------------------

local result =
    Engine.execute(
        "batch",
        batch,
        {
            profile = "default",

            vendor = {
                kind  = "vendor",
                items = vendor.boards,
                meta  = { name = vendor.id }
            },

            percentage = -10
        }
    )

-- print("\nRequests:")
-- I.print(result.requests)
--
-- print("\nCapability diff tree:\n")
-- I.print(result.capabilities)
--
-- print("\nEnrichment requests:\n")
--
-- if #result.requests == 0 then
--     print("No enrichment actions required.\n")
-- else
--     I.print(result.requests)
-- end
--
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

I.print(batch)

I.print(Engine.run("batch", batch).capabilities)
