-- classify/internal/partition.lua
--
-- Pure partition primitives.
--
-- PURPOSE
-- -------
-- Determine domain ownership of canonical fields and provide
-- low-level assignment utilities used during classification.
--
-- This module:
--   • Decides whether a canonical field belongs to BOARD or ORDER
--   • Assigns canonical fields into a destination table
--   • Tracks structural overwrites
--
-- This module does NOT:
--   • Perform alias resolution
--   • Perform reconciliation across rows
--   • Validate semantic correctness
--   • Perform tracing or orchestration
--
-- It is a minimal structural helper layer.

local Spec = require("platform.classify.internal.schema")

local Partition = {}

----------------------------------------------------------------
-- owner_of
--
-- Determine which domain owns a canonical field.
--
-- INPUT
--   canonical : canonical field name (already resolved by alias)
--
-- OUTPUT
--   Spec.DOMAIN.BOARD
--   Spec.DOMAIN.ORDER
--   nil (if canonical not declared in schema)
--
-- Ownership is determined strictly by classify.internal.schema.
----------------------------------------------------------------

---@param canonical string|nil
---@return string|nil
function Partition.owner_of(canonical)
    if canonical == nil then
        return nil
    end

    ------------------------------------------------------------
    -- BOARD domain
    ------------------------------------------------------------
    if Spec.board_fields[canonical] then
        return Spec.DOMAIN.BOARD
    end

    ------------------------------------------------------------
    -- ORDER domain
    ------------------------------------------------------------
    if Spec.order_fields[canonical] then
        return Spec.DOMAIN.ORDER
    end

    ------------------------------------------------------------
    -- Canonical key not declared in schema
    --
    -- This indicates a schema misalignment or an unexpected
    -- canonical field.
    ------------------------------------------------------------
    return nil
end

----------------------------------------------------------------
-- set_field
--
-- Assign a canonical field into a destination partition.
--
-- INPUT
--   dst         : table (board or order partition)
--   canonical   : canonical field name
--   value       : raw value (no coercion applied here)
--   diagnostics : table for recording overwrite events
--   raw_key     : original raw key that produced this canonical
--
-- Behavior:
--   • If canonical already exists in dst, record an overwrite
--     diagnostic (this is a structural duplicate within a
--     single object).
--   • Always overwrite with the latest value deterministically.
--
-- NOTE:
--   Overwrite tracking here is per-object only.
--   Cross-row reconciliation happens later in order_context.
----------------------------------------------------------------

---@param dst table
---@param canonical string
---@param value any
---@param diagnostics table
---@param raw_key string
function Partition.set_field(dst, canonical, value, diagnostics, raw_key)
    ------------------------------------------------------------
    -- Detect duplicate canonical assignment within the same object
    --
    -- Example:
    --   { "Order Number" = "A1", order_number = "A2" }
    --
    -- Both resolve to "order_number".
    -- This is a structural ambiguity at the object level.
    ------------------------------------------------------------
    if dst[canonical] ~= nil then
        diagnostics.overwrites = diagnostics.overwrites or {}
        diagnostics.overwrites[#diagnostics.overwrites + 1] = {
            canonical = canonical,
            from_key  = raw_key,
        }
    end

    ------------------------------------------------------------
    -- Deterministic last-write-wins assignment.
    --
    -- No validation or coercion occurs here.
    -- Downstream builders or reconciliation stages are responsible
    -- for semantic handling.
    ------------------------------------------------------------
    dst[canonical] = value
end

return Partition
