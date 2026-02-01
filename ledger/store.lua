-- ledger/store.lua

local LedgerDef = require("ledger.ledger")

local Store = {}

function Store.load(path)
    local ok, data = pcall(dofile, path)
    if ok and type(data) == "table" then
        data.meta       = data.meta or LedgerDef.new().meta
        data.facts      = data.facts or {}
        data.ingestions = data.ingestions or {}
        return data
    end
    return LedgerDef.new()
end

local function serialize(tbl, indent)
    indent = indent or ""
    local out = { "{" }
    for k, v in pairs(tbl) do
        local key = string.format("[%q] = ", tostring(k))
        if type(v) == "table" then
            table.insert(out, indent .. "  " .. key .. serialize(v, indent .. "  ") .. ",")
        elseif type(v) == "string" then
            table.insert(out, indent .. "  " .. key .. string.format("%q", v) .. ",")
        else
            table.insert(out, indent .. "  " .. key .. tostring(v) .. ",")
        end
    end
    table.insert(out, indent .. "}")
    return table.concat(out, "\n")
end

function Store.save(path, ledger)
    local f = assert(io.open(path, "w"))
    f:write("return ")
    f:write(serialize(ledger))
    f:close()
end

return Store
