-- ingestion_v2/record_board_dimension_premap.lua
--
-- Responsibility:
--   Pre-map and normalize board dimension fields required by Board.new():
--
--     base_h, base_w, l, ct, tag
--
-- This is a MECHANICAL, DOMAIN-SCOPED normalization step.
--
-- Guarantees:
--   • Deterministic
--   • No inference
--   • No parsing (e.g. "2x4" is INVALID)
--   • Numeric-only coercion via tonumber
--   • Field-scoped value normalization
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
    h           = "base_h",
    height      = "base_h",
    thickness   = "base_h",
    t           = "base_h",

    -- WIDTH
    w       = "base_w",
    width   = "base_w",

    -- LENGTH
    l       = "l",
    len     = "l",
    length  = "l",

    -- COUNT
    ct      = "ct",
    count   = "ct",
    qty     = "ct",
    quantity= "ct",

    -- TAG / NOMINAL
    tag     = "tag",
    flag    = "tag",
    nominal = "tag",
    ["n/f"] = "tag",
}

----------------------------------------------------------------
-- Field-scoped normalization rules
----------------------------------------------------------------

local NUMERIC_FIELDS = {
    base_h = true,
    base_w = true,
    l      = true,
    ct     = true,
}

local LOWERCASE_FIELDS = {
    tag = true,
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param record table
---@return table record -- same table, mutated
function Premap.apply(record)
    assert(type(record) == "table", "record_board_dimension_premap.apply(): record must be table")

    -- snapshot keys to avoid mutation hazards
    local keys = {}
    for k in pairs(record) do
        if type(k) == "string" then
            keys[#keys + 1] = k
        end
    end

    ----------------------------------------------------------------
    -- Key canonicalization
    ----------------------------------------------------------------
    for _, key in ipairs(keys) do
        local canonical = KEYMAP[key:lower()]
        if canonical and record[canonical] == nil then
            record[canonical] = record[key]
        end
    end

    ----------------------------------------------------------------
    -- Numeric normalization (NO parsing)
    ----------------------------------------------------------------
    for field in pairs(NUMERIC_FIELDS) do
        if record[field] ~= nil then
            record[field] = tonumber(record[field]) -- nil if invalid
        end
    end

    ----------------------------------------------------------------
    -- Field-scoped value normalization
    ----------------------------------------------------------------
    for field in pairs(LOWERCASE_FIELDS) do
        if type(record[field]) == "string" then
            record[field] = record[field]:lower()
        end
    end

    return record
end

return Premap
