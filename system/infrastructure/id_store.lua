local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

local IDStore = {}

local function counter_path(name)
    return Storage.runtime_ids() .. "/" .. name .. ".json"
end

local function read_counter(name)
    local path = counter_path(name)

    local data = FileGateway.read_json(path)
    if not data or type(data) ~= "table" then
        return 0
    end

    return tonumber(data.value) or 0
end

local function write_counter(name, value)
    local path = counter_path(name)

    local ok, err = FileGateway.write_json(path, {
        value = value
    })

    if not ok then
        error("IDStore write failed: " .. tostring(err))
    end
end

function IDStore.next(name, prefix)
    assert(type(name) == "string", "id_store name required")
    assert(type(prefix) == "string", "id_store prefix required")

    local n = read_counter(name) + 1
    write_counter(name, n)

    return prefix .. "-" .. string.format("%06d", n)
end

return IDStore
