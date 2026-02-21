-- classify/internal/normalize.lua
--
-- String normalization utilities for alias resolution.
--
-- PURPOSE
-- -------
-- Provide deterministic normalization rules used by the alias
-- resolution system to unify common key formatting differences.
--
-- This module:
--   • Performs simple structural string normalization
--   • Ensures predictable alias matching
--
-- This module does NOT:
--   • Perform semantic inference
--   • Perform fuzzy matching
--   • Attempt typo correction
--   • Apply domain logic
--
-- It exists purely to reduce superficial formatting variation
-- before alias lookup.

local Normalize = {}

----------------------------------------------------------------
-- Normalize.key
--
-- Canonicalizes a raw key into a predictable structural form.
--
-- Transformations applied (in order):
--   1. Trim leading/trailing whitespace
--   2. Replace common separators (space, '/', '-') with '_'
--   3. Collapse repeated underscores
--   4. Convert to lowercase
--
-- Examples:
--
--   "Job Number"     -> "job_number"
--   "price/bf"       -> "price_bf"
--   "Order-ID"       -> "order_id"
--   "  Customer  "   -> "customer"
--
-- This normalization is intentionally minimal and predictable.
-- It does not remove arbitrary characters or perform fuzzy logic.
--
---@param key string
---@return string normalized
function Normalize.key(key)
    assert(type(key) == "string", "Normalize.key(): string required")

    ------------------------------------------------------------
    -- 1. Trim whitespace
    ------------------------------------------------------------
    local s = key:match("^%s*(.-)%s*$")

    ------------------------------------------------------------
    -- 2. Normalize common separators
    --
    -- Any sequence of:
    --   space
    --   '/'
    --   '-'
    --
    -- becomes a single underscore.
    ------------------------------------------------------------
    s = s:gsub("[/%-%s]+", "_")

    ------------------------------------------------------------
    -- 3. Collapse accidental duplicate underscores
    ------------------------------------------------------------
    s = s:gsub("__+", "_")

    ------------------------------------------------------------
    -- 4. Lowercase for deterministic comparison
    ------------------------------------------------------------
    s = s:lower()

    return s
end

return Normalize
