-- ledger/identity.lua
--
-- Ledger-level identity.
-- Purpose:
--   Determine whether two ingested boards represent
--   the same ledger fact.

local Identity = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function normalize(v)
    return tostring(v or "")
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end

-- Deterministic string serialization (stable key order)
local function flatten(tbl, out, prefix)
    out = out or {}
    prefix = prefix or ""

    local keys = {}
    for k in pairs(tbl) do
        if type(k) == "string" then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)

    for _, k in ipairs(keys) do
        local v = tbl[k]
        local path = prefix == "" and k or (prefix .. "." .. k)

        if type(v) == "table" then
            flatten(v, out, path)
        else
            out[#out + 1] = path .. "=" .. normalize(v)
        end
    end

    return out
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Compute ledger content key
--- Includes:
---   • Full board snapshot
---   • Source identity (file path)
---
--- @param board table
--- @param source table
--- @return string
function Identity.compute(board, source)
    assert(type(board) == "table", "identity.compute(): board required")
    assert(type(source) == "table", "identity.compute(): source required")

    local parts = {}

    -- Board contents (lossless, stable)
    flatten(board, parts, "board")

    -- Source identity
    parts[#parts + 1] = "source.path=" .. normalize(source.path)

    table.sort(parts)

    return table.concat(parts, "|")
end

return Identity
