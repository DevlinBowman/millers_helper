-- system/infrastructure/ledger/index.lua

local IO    = require("platform.io.controller")
local AppFS = require("system.infrastructure.app_fs.controller")
local FS    = require("platform.io.registry").fs

local Index = {}

----------------------------------------------------------------
-- Internal
----------------------------------------------------------------

local function index_path()
    local ledger_root = AppFS.ledger():path()
    return FS.join(ledger_root, "index.json")
end

local function read_index()
    local path = index_path()

    if not FS.file_exists(path) then
        return {}
    end

    local result = IO.read_strict(path)
    return result.data or {}
end

local function write_index(data)
    local path = index_path()

    IO.write_strict(path, {
        codec = "json",
        data  = data
    })
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function Index.read_all()
    return read_index()
end

function Index.read_one(transaction_id)
    local all = read_index()

    for _, entry in ipairs(all) do
        if entry.transaction_id == transaction_id then
            return entry
        end
    end

    return nil
end

function Index.append(entry)
    local all = read_index()
    all[#all + 1] = entry
    write_index(all)
end

return Index
