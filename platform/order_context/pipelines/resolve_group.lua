-- order_context/pipelines/resolve_group.lua
--
-- Resolve one order group into a coherent order context.
--
-- PURPOSE
-- -------
-- Given a set of classified rows that are already grouped
-- as belonging to a single logical order, reconcile all
-- distributed order fragments into one canonical order table.
--
-- This module:
--   • Collects all order-domain fields present across rows
--   • Detects schema misalignment between classify and policy
--   • Normalizes values when required (e.g., dates)
--   • Delegates conflict decisions to Policy
--   • Produces:
--         - resolved order context
--         - signals describing reconciliation behavior
--         - decisions describing per-field resolution outcome
--
-- This module does NOT:
--   • Perform grouping (compress does that)
--   • Perform alias resolution (classify already did that)
--   • Build final domain objects
--   • Trace or enforce contracts
--
-- It is purely semantic reconciliation of one order group.

local Registry = require("platform.order_context.registry")

local ResolveGroup = {}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Resolve distributed order fragments for a single order group.
---
--- INPUT
---   rows : classified rows (already grouped by identity)
---   opts : optional behavior flags
---
--- OUTPUT
---   {
---     order     = table,     -- reconciled order context
---     signals   = table[],   -- reconciliation signals
---     decisions = table,     -- per-field decision metadata
---   }
---
function ResolveGroup.run(rows, opts)
    opts = opts or {}

    local Util   = Registry.util
    local Policy = Registry.policy
    local Spec   = Registry.spec
    local Signal = Registry.signal

    local resolved_order = {}
    local signals        = {}
    local decisions      = {}

    ----------------------------------------------------------------
    -- Phase 1: Collect all order fields present in this group
    --
    -- classify already partitioned row.order fragments.
    -- We now determine which canonical order fields exist at all.
    ----------------------------------------------------------------

    local fields = Util.collect_order_fields(rows)

    ----------------------------------------------------------------
    -- Phase 2: SPEC ALIGNMENT GUARD
    --
    -- If a field exists in classification output but has no
    -- declared reconciliation policy in order_context.spec,
    -- then classification and reconciliation schemas are misaligned.
    --
    -- We warn explicitly so architectural drift is visible.
    --
    -- Fallback behavior still defaults to Spec.default (strict),
    -- but this signal makes the misconfiguration observable.
    ----------------------------------------------------------------

    for _, field in ipairs(fields) do
        if Spec.fields[field] == nil then
            signals[#signals + 1] = Signal.new({
                kind       = "order_field_missing_policy",
                severity   = "warn",
                field      = field,
                values     = {},
                resolution = "implicit_strict",
                message    = (
                    "order field '%s' was produced by classification and assigned " ..
                    "to the ORDER domain, but no reconciliation policy exists in " ..
                    "order_context.spec. This indicates schema misalignment: " ..
                    "'%s' is recognized during classification but has no declared " ..
                    "conflict behavior during order resolution. " ..
                    "Please update order_context.internal.spec to declare a policy " ..
                    "for '%s', or revise classify.internal.schema if this field " ..
                    "should not belong to the ORDER domain."
                ):format(field, field, field),
            })
        end
    end

    ----------------------------------------------------------------
    -- Phase 3: Field-by-field reconciliation
    --
    -- For each canonical order field:
    --   1. Normalize values if required
    --   2. Collect distinct values across rows
    --   3. Apply policy decision
    --   4. Mutate resolved_order accordingly
    ----------------------------------------------------------------

    for _, field in ipairs(fields) do
        local field_spec = Spec.fields[field] or Spec.default

        -- Optional normalization (e.g., date formatting)
        local normalizer = nil
        if field_spec.normalize then
            normalizer = Util[field_spec.normalize]
        end

        -- Collect distinct values after optional normalization
        local values = Util.collect_order_field_values(rows, field, normalizer)

        ------------------------------------------------------------
        -- Case A: Field present but all values empty → ignore
        ------------------------------------------------------------
        if #values == 0 then
            -- No usable values for this field in this group.

        ------------------------------------------------------------
        -- Case B: Exactly one distinct value → deterministic keep
        ------------------------------------------------------------
        elseif #values == 1 then
            resolved_order[field] = values[1]
            decisions[field] = {
                action = "keep",
                value  = values[1],
            }

        ------------------------------------------------------------
        -- Case C: Multiple distinct values → delegate to Policy
        ------------------------------------------------------------
        else
            local decision = Policy.decide(field, values, rows, opts)

            decisions[field] = {
                action = decision.action,
                values = values,
            }

            -- Collect signal if policy emitted one
            if decision.signal then
                signals[#signals + 1] = decision.signal
            end

            --------------------------------------------------------
            -- Interpret decision.action
            --------------------------------------------------------

            if decision.action == "error" then
                -- Hard structural violation.
                -- Order group cannot be reconciled.
                error(
                    decision.signal and decision.signal.message
                    or ("order_context conflict on field: " .. tostring(field))
                )

            elseif decision.action == "defer_recalc_drop_field" then
                -- Field intentionally omitted.
                -- Downstream builder expected to recompute.
                -- No mutation here.

            elseif decision.action == "keep_first" then
                resolved_order[field] = values[1]

            elseif decision.action == "keep" then
                resolved_order[field] = values[1]

            elseif decision.action == "drop" then
                -- Explicit drop. Field omitted intentionally.

            else
                error(
                    "order_context: unknown decision action: " ..
                    tostring(decision.action)
                )
            end
        end
    end

    ----------------------------------------------------------------
    -- Final Output
    --
    -- resolved_order contains only fields that survived policy.
    -- signals describe reconciliation events.
    -- decisions provide introspection into what happened.
    ----------------------------------------------------------------

    return {
        order     = resolved_order,
        signals   = signals,
        decisions = decisions,
    }
end

return ResolveGroup
