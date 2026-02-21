-- order_context/internal/policy.lua
--
-- Spec-driven conflict resolution engine.
--
-- PURPOSE
-- -------
-- Given a single order field and multiple distinct values collected
-- across classified rows in a group, decide how to reconcile them.
--
-- This module:
--   • Does NOT mutate rows
--   • Does NOT perform grouping
--   • Does NOT normalize keys
--   • Does NOT build the final order
--
-- It ONLY answers the question:
--
--   "If multiple values exist for this canonical order field,
--    what should happen?"
--
-- The behavior is fully driven by order_context.internal.spec.
--
-- Pure logic. No tracing. No orchestration.

local Util   = require("platform.order_context.internal.util")
local Signal = require("platform.order_context.internal.signal")
local Spec   = require("platform.order_context.internal.spec")

local Policy = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

-- Fetch declared reconciliation policy for a field.
-- Falls back to Spec.default if no explicit entry exists.
--
-- NOTE:
-- The spec-alignment guard in resolve_group should already warn
-- if a field is missing from Spec.fields. This fallback ensures
-- deterministic behavior even if that guard is bypassed.
local function get_field_spec(field)
    return Spec.fields[field] or Spec.default
end

-- Construct a hard conflict error decision.
-- Used when reconciliation is impossible or forbidden.
local function build_error(field, values)
    return {
        action = "error",
        signal = Signal.new({
            kind       = "order_field_conflict",
            severity   = "error",
            field      = field,
            values     = values,
            resolution = "error",
            message    = (
                "conflicting order field '%s': %s. " ..
                "Multiple distinct values detected within a single order group " ..
                "and the field policy is strict."
            ):format(field, table.concat(values, ", ")),
        }),
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Decide resolution strategy for a conflicting field.
---
--- INPUT
---   field  : canonical order field name
---   values : distinct stringified values found across rows
---   rows   : classified rows in the group (used for recalculation predicates)
---   opts   : optional future behavior toggles
---
--- OUTPUT
---   decision {
---       action = string,
---       signal = table|nil
---   }
---
--- ACTIONS
---   "error"
---   "keep_first"
---   "keep"
---   "defer_recalc_drop_field"
---   "drop"
---
function Policy.decide(field, values, rows, opts)
    opts = opts or {}

    local spec = get_field_spec(field)

    ----------------------------------------------------------------
    -- STRICT
    --
    -- Identity-critical fields.
    -- Any disagreement means the grouped rows do not represent
    -- a single coherent order.
    ----------------------------------------------------------------
    if spec.conflict == "strict" then
        return build_error(field, values)
    end

    ----------------------------------------------------------------
    -- KEEP_FIRST
    --
    -- Deterministic but non-fatal.
    -- Used for descriptive / contextual fields where conflict
    -- does not invalidate order identity.
    ----------------------------------------------------------------
    if spec.conflict == "keep_first" then
        return {
            action = "keep_first",
            signal = Signal.new({
                kind       = "order_field_keep_first",
                severity   = "warn",
                field      = field,
                values     = values,
                resolution = "keep_first",
                message    = (
                    "conflicting field '%s'; multiple values detected. " ..
                    "Field is non-identity; keeping first value deterministically."
                ):format(field),
            }),
        }
    end

    ----------------------------------------------------------------
    -- RECALCULABLE
    --
    -- Numeric or builder-derived fields.
    --
    -- These fields may:
    --   • Be provided directly
    --   • Be derived later from board data
    --   • Contain sentinel tokens ("0", blanks, etc.)
    --
    -- Policy logic attempts to:
    --   1. Preserve a single numeric value if safe
    --   2. Drop field and defer to builder if recomputation is possible
    --   3. Error if conflict is irreconcilable
    ----------------------------------------------------------------
    if spec.conflict == "recalculable" then

        local numeric_values   = {}
        local has_non_numeric  = false

        -- Separate numeric vs non-numeric tokens
        for _, v in ipairs(values) do
            if Util.is_numeric(v) then
                numeric_values[#numeric_values + 1] = tonumber(v)
            else
                has_non_numeric = true
            end
        end

        ------------------------------------------------------------
        -- Multiple numeric values → ambiguous numeric conflict
        ------------------------------------------------------------
        if #numeric_values > 1 then
            return build_error(field, values)
        end

        ------------------------------------------------------------
        -- Non-numeric tokens allowed (sentinel handling)
        --
        -- Example: value = "0" or blank in one row,
        -- but real numeric present elsewhere.
        --
        -- If sentinel_strategy = "drop", remove field entirely
        -- so downstream builder recomputes.
        ------------------------------------------------------------
        if has_non_numeric and spec.allow_sentinel then
            if spec.sentinel_strategy == "drop" then
                return {
                    action = "defer_recalc_drop_field",
                    signal = Signal.new({
                        kind       = "order_field_deferred",
                        severity   = "info",
                        field      = field,
                        values     = values,
                        resolution = "defer_recalc",
                        message    = (
                            "non-numeric or sentinel value detected for '%s'; " ..
                            "dropping field to allow downstream recalculation."
                        ):format(field),
                    }),
                }
            end
        end

        ------------------------------------------------------------
        -- Exactly one numeric value → safe to keep
        ------------------------------------------------------------
        if #numeric_values == 1 then
            return { action = "keep" }
        end

        ------------------------------------------------------------
        -- Conditional recalculation allowed
        --
        -- Some fields require structural conditions to permit
        -- recomputation (e.g., all boards must have bf_price).
        ------------------------------------------------------------
        if spec.recalc_requires then
            local predicate = Util[spec.recalc_requires]
            if predicate and predicate(rows) then
                return {
                    action = "defer_recalc_drop_field",
                    signal = Signal.new({
                        kind       = "order_field_recalc",
                        severity   = "warn",
                        field      = field,
                        values     = values,
                        resolution = "defer_recalc",
                        message    = (
                            "conflicting '%s'; structural requirements satisfied. " ..
                            "Dropping field so builder can recalculate."
                        ):format(field),
                    }),
                }
            end
        end

        ------------------------------------------------------------
        -- No safe resolution path
        ------------------------------------------------------------
        return build_error(field, values)
    end

    ----------------------------------------------------------------
    -- Unknown conflict type
    ----------------------------------------------------------------
    error(
        "order_context.policy: unknown conflict type for field '" ..
        tostring(field) ..
        "'"
    )
end

return Policy
