-- tests/ledger/test_infrastructure.lua

local Backend = require("system.backend")
local app     = Backend.run("default")

local Index   = require("system.infrastructure.ledger.index")
local Bundle  = require("system.infrastructure.ledger.bundle")

print("\n--- INFRA TEST ---")

-- fake transaction
local txn_id = "txn_test_002"

local entry = {
    transaction_id = txn_id,
    type = "sale",
    date = "2026-01-01",
    value = 123.45,
    total_bf = 50,
}

local order = { order_number = "TEST-1" }
local boards = { { id = "b1", bf_batch = 60 } }

-- write bundle
Bundle.write(txn_id, entry, order, boards)

-- append index
Index.append(entry)

-- read back
local read_entry = Index.read_one(txn_id)
assert(read_entry.transaction_id == txn_id)

local bundle = Bundle.read(txn_id)
assert(bundle.entry.transaction_id == txn_id)

print("✓ infrastructure write/read OK")
