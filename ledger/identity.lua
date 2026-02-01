-- ledger/identity.lua
--
-- Ledger-level identity.
-- Purpose:
--   Determine whether two ingested boards represent
--   the same ledger fact.
--
-- Identity MUST be:
--   • stable across runs
--   • derived-field agnostic
--   • deterministic
--
-- Identity includes:
--   • board snapshot (label + ct + optional qualifiers)
--   • source file path
--
-- NOTE:
--   source.line is provenance, NOT identity.

local Identity = {}

local function norm(v)
    return tostring(v or "")
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end

--- Compute ledger content key (v1)
--- @param board table
--- @param source table -- { path = string }
--- @return string
function Identity.compute(board, source)
    assert(type(board) == "table", "identity.compute(): board required")
    assert(type(source) == "table", "identity.compute(): source required")
    assert(type(source.path) == "string", "identity.compute(): source.path required")

    return table.concat({
        "v1",
        norm(board.label),
        norm(board.ct),
        norm(board.species),
        norm(board.grade),
        norm(board.moisture),
        norm(board.surface),
        norm(source.path),
    }, "|")
end

return Identity
