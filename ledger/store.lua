-- ledger/store.lua
--
-- Durable Lua-table persistence.

local LedgerDef = require("ledger.ledger")

local Store = {}

----------------------------------------------------------------
-- Load
----------------------------------------------------------------

function Store.load(path)
    local ok, data = pcall(dofile, path)
    if ok and type(data) == "table" then
        data.meta  = data.meta or LedgerDef.new().meta
        data.facts = data.facts or {}

        -- NORMALIZE INGESTIONS (CRITICAL)
        if type(data.ingestions) ~= "table" then
            data.ingestions = {}
        else
            if #data.ingestions == 0 then
                local list = {}
                for _, v in pairs(data.ingestions) do
                    list[#list + 1] = v
                end
                table.sort(list, function(a, b)
                    return tostring(a.at) < tostring(b.at)
                end)
                data.ingestions = list
            end
        end

        return data
    end
    return LedgerDef.new()
end

----------------------------------------------------------------
-- Save
----------------------------------------------------------------

local function serialize(tbl, indent)
    indent = indent or ""
    local out = { "{" }

    for k, v in pairs(tbl) do
        local key = string.format("[%q] = ", tostring(k))
        if type(v) == "table" then
            out[#out + 1] = indent .. "  " .. key .. serialize(v, indent .. "  ") .. ","
        elseif type(v) == "string" then
            out[#out + 1] = indent .. "  " .. key .. string.format("%q", v) .. ","
        else
            out[#out + 1] = indent .. "  " .. key .. tostring(v) .. ","
        end
    end

    out[#out + 1] = indent .. "}"
    return table.concat(out, "\n")
end

function Store.save(path, ledger)
    local f = assert(io.open(path, "w"))
    f:write("return ")
    f:write(serialize(ledger))
    f:close()
end

return Store
