local IO = require("platform.io.controller")
local FS = require("platform.io.registry").fs

local Ledger = {}

local LEDGER_PATH = "data/transaction_ledger.lua"

local function load_ledger()
    if not FS.file_exists(LEDGER_PATH) then
        return {}
    end

    local result = IO.read_strict(LEDGER_PATH)
    return result.data
end

local function write_ledger(tbl)
    IO.write_strict(LEDGER_PATH, {
        codec = "lua",
        data  = tbl,
    })
end

function Ledger.find_by_signature(order_id, date, type_)
    local ledger = load_ledger()

    for _, entry in ipairs(ledger) do
        if entry.order_id == order_id
            and entry.date == date
            and entry.type == type_
        then
            return entry
        end
    end

    return nil
end

function Ledger.read_all()
    return load_ledger()
end

function Ledger.read_one(transaction_id)
    local ledger = load_ledger()

    for _, entry in ipairs(ledger) do
        if entry.transaction_id == transaction_id then
            return entry
        end
    end

    return nil
end

function Ledger.append(entry)
    local ledger = load_ledger()

    ledger[#ledger + 1] = {
        transaction_id = entry.transaction_id,
        date           = entry.date,
        type           = entry.type,
        order_id       = entry.order_id,
        customer_id    = entry.customer_id,
        value          = entry.value,
        total_bf       = entry.total_bf,
    }

    write_ledger(ledger)
end

return Ledger
