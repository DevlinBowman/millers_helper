local IO = require("io.controller")
local FS = require("io.registry").fs

local Storage = {}

local ROOT = "data/transactions"

local function ensure_dir(path)
    FS.ensure_parent_dir(path .. "/dummy")
    os.execute(string.format("mkdir -p %q", path))
end

function Storage.read_bundle(transaction_id)
    local dir = ROOT .. "/" .. transaction_id

    local entry  = IO.read_strict(dir .. "/entry.json").data
    local order  = IO.read_strict(dir .. "/order.json").data
    local boards = IO.read_strict(dir .. "/boards.json").data

    return {
        entry  = entry,
        order  = order,
        boards = boards,
    }
end

local function write_json(path, data)
    return IO.write_strict(path, {
        codec = "json",
        data  = data,
    })
end

function Storage.write_bundle(transaction_id, entry, order, boards)
    assert(type(transaction_id) == "string", "transaction_id required")
    assert(type(entry) == "table", "entry required")
    assert(type(order) == "table", "order required")
    assert(type(boards) == "table", "boards required")

    local dir = ROOT .. "/" .. transaction_id
    ensure_dir(dir)

    ------------------------------------------------------------
    -- Write canonical entry
    ------------------------------------------------------------
    write_json(dir .. "/entry.json", entry)

    ------------------------------------------------------------
    -- Write full order object
    ------------------------------------------------------------
    write_json(dir .. "/order.json", order)

    ------------------------------------------------------------
    -- Write full boards array
    ------------------------------------------------------------
    write_json(dir .. "/boards.json", boards)

    return true
end

return Storage
