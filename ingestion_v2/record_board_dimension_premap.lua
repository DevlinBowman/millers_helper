-- ingestion_v2/record_board_dimension_premap.lua
--
-- Responsibility:
--   Pre-map and numerically normalize board dimension fields
--   required by Board.new():
--
--     base_h, base_w, l, ct, tag
--
-- This is a MECHANICAL, LOSSLESS normalization step.
--
-- Guarantees:
--   • Deterministic
--   • No inference
--   • No parsing (e.g. "2x4" is INVALID)
--   • Numeric-only coercion via tonumber
--   • Invalid values become nil
--   • No validation
--   • No side effects beyond key assignment
--
-- This MUST run:
--   AFTER record_builder
--   BEFORE record_validator
--   BEFORE Board.new

local Premap = {}

----------------------------------------------------------------
-- Explicit, domain-known key map
----------------------------------------------------------------

local KEYMAP = {
    -- HEIGHT / THICKNESS
    H         = "base_h",
    h         = "base_h",
    Height    = "base_h",
    height    = "base_h",
    Thickness = "base_h",
    thickness = "base_h",
    T         = "base_h",

    -- WIDTH
    W       = "base_w",
    w       = "base_w",
    Width   = "base_w",
    width   = "base_w",

    -- LENGTH
    L       = "l",
    l       = "l",
    Length  = "l",
    length  = "l",
    Len     = "l",
    len     = "l",

    -- COUNT
    CT    = "ct",
    Ct    = "ct",
    ct    = "ct",
    Count = "ct",
    count = "ct",
    Qty   = "ct",
    qty   = "ct",

    -- TAG (string only)
    Tag     = "tag",
    tag     = "tag",
    Nominal = "tag",
    ["N/F"] = "tag",
}

local NUMERIC_FIELDS = {
    base_h = true,
    base_w = true,
    l      = true,
    ct     = true,
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param record table
---@return table record -- same table, mutated
function Premap.apply(record)
    assert(type(record) == "table", "record_board_dimension_premap.apply(): record must be table")

    -- Snapshot keys to avoid mutation hazards
    local keys = {}
    for k in pairs(record) do
        keys[#keys + 1] = k
    end

    for _, key in ipairs(keys) do
        local canonical = KEYMAP[key]
        if canonical and record[canonical] == nil then
            record[canonical] = record[key]
        end
    end

    -- Numeric normalization (NO parsing)
    for field in pairs(NUMERIC_FIELDS) do
        if record[field] ~= nil then
            local n = tonumber(record[field])
            record[field] = n  -- nil if invalid, numeric if valid
        end
    end

    return record
end

return Premap
