-- system/infrastructure/txn_store.lua
--
-- Transaction bundle persistence:
--   txn/{id}/entry.json
--   txn/{id}/order.json
--   txn/{id}/boards.json
--
-- Infrastructure only. No ledger rules.

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

local TxnStore = {}

local function txn_file(ledger_id, txn_id, name)
    -- Uses storage schema; no manual "data/".
    return Storage.ledger_txn_file(ledger_id, txn_id, name)
end

--- @return table|nil bundle
--- @return string|nil err
function TxnStore.read_bundle(ledger_id, txn_id)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    assert(type(txn_id) == "string" and txn_id ~= "", "txn_id required")

    local entry_env, entry_err = FileGateway.read(txn_file(ledger_id, txn_id, "entry"))
    if not entry_env then return nil, entry_err end

    local order_env, order_err = FileGateway.read(txn_file(ledger_id, txn_id, "order"))
    if not order_env then return nil, order_err end

    local boards_env, boards_err = FileGateway.read(txn_file(ledger_id, txn_id, "boards"))
    if not boards_env then return nil, boards_err end

    return {
        entry  = entry_env.data,
        order  = order_env.data,
        boards = boards_env.data,
    }
end

--- @return true|nil ok
--- @return string|nil err
function TxnStore.write_bundle(ledger_id, txn_id, entry, order, boards)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    assert(type(txn_id) == "string" and txn_id ~= "", "txn_id required")
    assert(type(entry) == "table", "entry required")
    assert(type(order) == "table", "order required")
    assert(type(boards) == "table", "boards required")

    local m1, e1 = FileGateway.write(txn_file(ledger_id, txn_id, "entry"),  "json", entry)
    if not m1 then return nil, e1 end

    local m2, e2 = FileGateway.write(txn_file(ledger_id, txn_id, "order"),  "json", order)
    if not m2 then return nil, e2 end

    local m3, e3 = FileGateway.write(txn_file(ledger_id, txn_id, "boards"), "json", boards)
    if not m3 then return nil, e3 end

    return true
end

return TxnStore
