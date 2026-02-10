-- ledger/analysis/keys.lua
--
-- Responsibility:
--   Introspect ledger + board data shape.
--
-- Provides:
--   • Board-supported keys (schema-defined)
--   • Derived / computed board keys
--   • Keys observed in ledger facts
--
-- Guarantees:
--   • Read-only
--   • Deterministic
--   • No IO
--   • No mutation

local Schema = require("core.board.schema")

local Keys = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function sorted_keys(t)
    local out = {}
    for k in pairs(t) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

----------------------------------------------------------------
-- Board surface (authoritative capability)
----------------------------------------------------------------

local function board_schema_keys()
    local keys = {
        authoritative = {},
        derived       = {},
        contextual    = {},
    }

    for name, def in pairs(Schema.fields) do
        local role = def.role or "authoritative"
        keys[role] = keys[role] or {}
        keys[role][name] = true
    end

    return {
        authoritative = sorted_keys(keys.authoritative),
        derived       = sorted_keys(keys.derived),
        contextual    = sorted_keys(keys.contextual),
        all           = sorted_keys(Schema.fields),
    }
end

----------------------------------------------------------------
-- Ledger surface (observed)
----------------------------------------------------------------

local function ledger_keys(ledger)
    local seen = {}

    if type(ledger.facts) == "table" then
        for _, fact in ipairs(ledger.facts) do
            local board = fact.board
            if type(board) == "table" then
                for k in pairs(board) do
                    seen[k] = true
                end
            end
        end
    end

    return sorted_keys(seen)
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Introspect board + ledger key surface
---
--- @param ledger table|nil
--- @return table
function Keys.run(ledger)
    local board = board_schema_keys()

    local result = {
        board = board,
    }

    if ledger then
        result.ledger = {
            observed = ledger_keys(ledger),
        }
    end

    return result
end

return Keys
