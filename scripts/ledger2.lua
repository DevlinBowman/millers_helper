-- scripts/test_ledger_from_runtime.lua
--
-- End-to-end validation of:
--   Runtime.load
--   Runtime.associate
--   Ledger.commit
--   Ledger.read_all / read_bundle
--
-- NO api.*
-- NO ingestion shortcuts
-- Runtime is the only boundary

local Runtime = require("core.domain.runtime.controller")
local Ledger  = require("core.domain.ledger.controller")
local I       = require("inspector")

----------------------------------------------------------------
-- Paths (adjust as needed)
----------------------------------------------------------------

local ORDER_ONLY_PATH =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/no_boards.txt"

local BOARDS_ONLY_PATH =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt"

local COMBINED_PATH =
    "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/compiled_lumber_orders.csv"

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function banner(title)
    print("\n" .. string.rep("=", 70))
    print(title)
    print(string.rep("=", 70))
end

local function assert_batch_shape(batch, label)
    assert(type(batch) == "table", label .. ": batch not table")
    assert(type(batch.order) == "table", label .. ": missing order")
    assert(type(batch.boards) == "table", label .. ": missing boards")
end

----------------------------------------------------------------
-- 1. Runtime load (combined input)
----------------------------------------------------------------

banner("1. RUNTIME LOAD (COMBINED INPUT)")

local runtime_combined = Runtime.load(
    COMBINED_PATH,
    { name = "combined_test", category = "order" }
)

-- I.print(runtime_combined, { shape_only = true })

local batch_combined = runtime_combined:batch(1)
assert_batch_shape(batch_combined, "combined")

print("boards:", #batch_combined.boards)

----------------------------------------------------------------
-- 2. Runtime load (split inputs)
----------------------------------------------------------------

banner("2. RUNTIME LOAD (ORDER ONLY + BOARDS ONLY)")

local runtime_orders = Runtime.load(
    ORDER_ONLY_PATH,
    { name = "orders_only", category = "order" }
)

local runtime_boards = Runtime.load(
    BOARDS_ONLY_PATH,
    { name = "boards_only", category = "boards" }
)

-- I.print(runtime_orders, { shape_only = true })
-- I.print(runtime_boards, { shape_only = true })

----------------------------------------------------------------
-- 3. Runtime association
----------------------------------------------------------------

banner("3. RUNTIME ASSOCIATION")

local runtime_associated = Runtime.associate(
    runtime_orders,
    runtime_boards,
    { name = "associated", category = "order" }
)

-- I.print(runtime_associated, { shape_only = true })

local assoc_batch = runtime_associated:batch(1)
assert_batch_shape(assoc_batch, "associated")

print("associated boards:", #assoc_batch.boards)

----------------------------------------------------------------
-- 4. Ledger commit (combined)
----------------------------------------------------------------

banner("4. LEDGER COMMIT (COMBINED)")

local result_combined = Ledger.commit(runtime_combined)

assert(type(result_combined.transactions) == "table", "no transactions returned")

print("transactions committed:", #result_combined.transactions)

----------------------------------------------------------------
-- 5. Ledger commit (associated, idempotent)
----------------------------------------------------------------

banner("5. LEDGER COMMIT (ASSOCIATED, IDEMPOTENT)")

local result_assoc = Ledger.commit(runtime_associated)

print("transactions returned:", #result_assoc.transactions)

----------------------------------------------------------------
-- 6. Ledger commit (FORCE overwrite)
----------------------------------------------------------------

banner("6. LEDGER COMMIT (FORCE)")

local result_force = Ledger.commit(runtime_associated, { force = true })

print("transactions forced:", #result_force.transactions)

----------------------------------------------------------------
-- 7. Ledger readback
----------------------------------------------------------------

banner("7. LEDGER READ ALL")

local all = Ledger.read_all()
assert(type(all.transactions) == "table", "read_all failed")

print("ledger entries:", #all.transactions)

for i, entry in ipairs(all.transactions) do
    print(string.format(
        "%02d | %s | %s | $%s | bf=%s",
        i,
        entry.transaction_id,
        entry.type,
        tostring(entry.value),
        tostring(entry.total_bf)
    ))
end

----------------------------------------------------------------
-- 8. Ledger bundle hydration
----------------------------------------------------------------

banner("8. LEDGER BUNDLE HYDRATION")

local first = all.transactions[1]
assert(first and first.transaction_id, "no transaction to hydrate")

local bundle = Ledger.read_bundle(first.transaction_id)

assert(type(bundle.order) == "table", "bundle missing order")
assert(type(bundle.boards) == "table", "bundle missing boards")

print("hydrated order_number:", bundle.order.order_number)
print("hydrated boards:", #bundle.boards)

----------------------------------------------------------------
-- 9. Provenance check
----------------------------------------------------------------

banner("9. PROVENANCE CHECK")

local meta = assoc_batch.meta or {}

if meta.io then
    print("io.source_path:", meta.io.source_path)
else
    print("WARNING: no io provenance on associated batch")
end

----------------------------------------------------------------
-- 10. Negative test: non-order category
----------------------------------------------------------------

banner("10. NEGATIVE TEST (NON-ORDER CATEGORY)")

local bad_runtime = Runtime.load(
    COMBINED_PATH,
    { name = "bad", category = "vendor" }
)

local ok, err = pcall(function()
    Ledger.commit(bad_runtime)
end)

if ok then
    error("expected ledger commit failure for non-order category")
else
    print("expected failure:", err)
end

----------------------------------------------------------------
-- DONE
----------------------------------------------------------------

banner("LEDGER TEST COMPLETE")
