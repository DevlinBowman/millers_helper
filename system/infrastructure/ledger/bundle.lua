-- system/infrastructure/ledger/bundle.lua

local IO    = require("platform.io.controller")
local AppFS = require("system.infrastructure.app_fs.controller")
local FS    = require("platform.io.registry").fs

local Bundle = {}

----------------------------------------------------------------
-- Internal
----------------------------------------------------------------

local function bundles_root()
    local ledger_root = AppFS.ledger():path()
    return FS.join(ledger_root, "bundles")
end

local function bundle_dir(transaction_id)
    return FS.join(bundles_root(), transaction_id)
end

local function file_path(transaction_id, name)
    return FS.join(bundle_dir(transaction_id), name .. ".json")
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function Bundle.write(transaction_id, entry, order, boards, allocations)

    IO.write_strict(file_path(transaction_id, "entry"), {
        codec = "json",
        data  = entry
    })

    IO.write_strict(file_path(transaction_id, "order"), {
        codec = "json",
        data  = order
    })

    IO.write_strict(file_path(transaction_id, "boards"), {
        codec = "json",
        data  = boards
    })

    IO.write_strict(file_path(transaction_id, "allocations"), {
        codec = "json",
        data  = allocations or {}
    })
end


function Bundle.read(transaction_id)

    local allocations = {}

    local ok, result = pcall(function()
        return IO.read_strict(file_path(transaction_id, "allocations"))
    end)

    if ok and result and result.data then
        allocations = result.data
    end

    return {
        entry       = IO.read_strict(file_path(transaction_id, "entry")).data,
        order       = IO.read_strict(file_path(transaction_id, "order")).data,
        boards      = IO.read_strict(file_path(transaction_id, "boards")).data,
        allocations = allocations,
    }
end

return Bundle
