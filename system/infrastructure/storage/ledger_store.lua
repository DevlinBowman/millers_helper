-- system/infrastructure/ledger_store.lua
--
-- Ledger registry persistence.
-- Stores a list of summary rows in ledger.json under a ledger_id root.
--
-- Infrastructure only.

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

local LedgerStore = {}

local function ledger_path(ledger_id)
    return Storage.ledger_file(ledger_id)
end

local function read_or_empty(ledger_id)
    local env = FileGateway.read(ledger_path(ledger_id))
    if not env then
        return {}
    end

    if type(env.data) ~= "table" then
        return {}
    end

    return env.data
end

local function write_all(ledger_id, rows)
    return FileGateway.write(ledger_path(ledger_id), "json", rows)
end

function LedgerStore.read_all(ledger_id)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    return read_or_empty(ledger_id)
end

function LedgerStore.read_one(ledger_id, txn_id)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    assert(type(txn_id) == "string" and txn_id ~= "", "txn_id required")

    local rows = read_or_empty(ledger_id)

    for _, row in ipairs(rows) do
        if row.transaction_id == txn_id then
            return row
        end
    end

    return nil
end

function LedgerStore.find_by_signature(ledger_id, order_id, date, type_)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    assert(type(order_id) == "string" and order_id ~= "", "order_id required")
    assert(type(date) == "string" and date ~= "", "date required")
    assert(type(type_) == "string" and type_ ~= "", "type required")

    local rows = read_or_empty(ledger_id)

    for _, row in ipairs(rows) do
        if row.order_id == order_id
            and row.date == date
            and row.type == type_
        then
            return row
        end
    end

    return nil
end

--- Append a summary row to ledger.json
--- @param ledger_id string
--- @param entry table -- expects summary fields already projected by domain/service
--- @return true|nil ok
--- @return string|nil err
function LedgerStore.append(ledger_id, entry)
    assert(type(ledger_id) == "string" and ledger_id ~= "", "ledger_id required")
    assert(type(entry) == "table", "entry required")
    assert(type(entry.transaction_id) == "string" and entry.transaction_id ~= "", "entry.transaction_id required")

    local rows = read_or_empty(ledger_id)

    rows[#rows + 1] = entry

    local meta, err = write_all(ledger_id, rows)
    if not meta then
        return nil, err
    end

    return true
end

return LedgerStore
