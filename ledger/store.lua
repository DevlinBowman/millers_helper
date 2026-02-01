-- ledger/store.lua
--
-- Durable Lua-table persistence.
-- CRITICAL:
--   Preserve numeric array keys as numbers (not strings),
--   otherwise dofile() reload breaks ipairs/# and dedupe.

local LedgerDef = require("ledger.ledger")

local Store = {}

----------------------------------------------------------------
-- Helpers: normalization (load)
----------------------------------------------------------------

local function is_numeric_string(k)
    if type(k) ~= "string" then return false end
    local n = tonumber(k)
    return n ~= nil and tostring(n) == k
end

local function normalize_array(tbl)
    if type(tbl) ~= "table" then return {} end

    -- already an array
    if #tbl > 0 then
        return tbl
    end

    -- convert numeric-string keys → numeric array
    local max_i = 0
    local tmp = {}

    for k, v in pairs(tbl) do
        if type(k) == "number" then
            tmp[k] = v
            if k > max_i then max_i = k end
        elseif is_numeric_string(k) then
            local nk = tonumber(k)
            tmp[nk] = v
            if nk > max_i then max_i = nk end
        end
    end

    local out = {}
    for i = 1, max_i do
        local v = tmp[i]
        if v ~= nil then
            out[#out + 1] = v
        end
    end

    return out
end

----------------------------------------------------------------
-- Load
----------------------------------------------------------------

function Store.load(path)
    local ok, data = pcall(dofile, path)
    if ok and type(data) == "table" then
        data.meta  = data.meta or LedgerDef.new().meta

        -- facts must be an array
        data.facts = normalize_array(data.facts or {})

        -- ingestions must be an array
        data.ingestions = normalize_array(data.ingestions or {})

        return data
    end

    return LedgerDef.new()
end

----------------------------------------------------------------
-- Helpers: serialization (save)
----------------------------------------------------------------

local function escape_string(s)
    return string.format("%q", s)
end

local function format_key(k)
    if type(k) == "number" then
        return string.format("[%d] = ", k)
    end
    return string.format("[%s] = ", escape_string(tostring(k)))
end

local function sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then
            return ta < tb
        end
        if ta == "number" then
            return a < b
        end
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function serialize_value(v, indent)
    indent = indent or ""
    local tv = type(v)

    if tv == "table" then
        return Store._serialize_table(v, indent)
    elseif tv == "string" then
        return escape_string(v)
    elseif tv == "number" or tv == "boolean" then
        return tostring(v)
    elseif v == nil then
        return "nil"
    else
        return escape_string(tostring(v))
    end
end

-- Serialize table with stable ordering:
--   1) array part via ipairs (1..n)
--   2) remaining keys sorted
function Store._serialize_table(tbl, indent)
    local out = { "{" }
    local next_indent = indent .. "  "

    -- array part
    local n = #tbl
    for i = 1, n do
        local key = format_key(i)
        out[#out + 1] = next_indent .. key .. serialize_value(tbl[i], next_indent) .. ","
    end

    -- remaining keys
    local keys = sorted_keys(tbl)
    for _, k in ipairs(keys) do
        local is_array_key = (type(k) == "number" and k >= 1 and k <= n and math.floor(k) == k)
        if not is_array_key then
            local key = format_key(k)
            out[#out + 1] = next_indent .. key .. serialize_value(tbl[k], next_indent) .. ","
        end
    end

    out[#out + 1] = indent .. "}"
    return table.concat(out, "\n")
end

function Store.save(path, ledger)
    local f = assert(io.open(path, "w"))
    f:write("return ")
    f:write(Store._serialize_table(ledger, ""))
    f:close()
end

return Store
