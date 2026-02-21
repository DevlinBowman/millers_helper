-- system/infrastructure/id_store.lua
--
-- Persistent ID counter store.
-- Uses Storage schema + FileGateway.
-- No hardcoded paths.

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

local IDStore     = {}

local function counter_path(name)
    return Storage.runtime_ids() .. "/" .. name .. ".id"
end

local function read_counter(name)
    local path = counter_path(name)

    local result, err = FileGateway.read(path)

    if not result then
        return 0
    end

    local value = tonumber(result.data) or 0
    return value
end

local function write_counter(name, value)
    local path = counter_path(name)

    local ok, err = FileGateway.write(
        path,
        "raw",
        tostring(value)
    )

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
