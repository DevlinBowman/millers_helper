-- platform/order_context/pipelines/resolve_group.lua
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

    ------------------------------------------------------------
    -- Phase 1: Collect order fields
    ------------------------------------------------------------

    local fields = Util.collect_order_fields(rows)

    ------------------------------------------------------------
    -- Phase 2: Spec alignment guard
    ------------------------------------------------------------

    for _, field in ipairs(fields) do
        if Spec.fields[field] == nil then
            signals[#signals + 1] = Signal.new({
                kind       = "order_field_missing_policy",
                severity   = "warn",
                field      = field,
                values     = {},
                resolution = "implicit_strict",
                message    = (
                    "order field '%s' produced by classification has no declared reconciliation policy."
                ):format(field),
            })
        end
    end

    ------------------------------------------------------------
    -- Phase 3: Field reconciliation
    ------------------------------------------------------------

    for _, field in ipairs(fields) do
        local field_spec = Spec.fields[field] or Spec.default

        local normalizer = nil
        if field_spec.normalize then
            normalizer = Util[field_spec.normalize]
        end

        local values = Util.collect_order_field_values(rows, field, normalizer)

        --------------------------------------------------------
        -- No usable values
        --------------------------------------------------------
        if #values == 0 then

        --------------------------------------------------------
        -- Single value
        --------------------------------------------------------
        elseif #values == 1 then
            resolved_order[field] = values[1]
            decisions[field] = {
                action = "keep",
                value  = values[1],
            }

        --------------------------------------------------------
        -- Multiple distinct values
        --------------------------------------------------------
        else
            local decision = Policy.decide(field, values, rows, opts)

            decisions[field] = {
                action = decision.action,
                values = values,
            }

            if decision.signal then
                signals[#signals + 1] = decision.signal
            end

            ----------------------------------------------------
            -- Interpret decision
            ----------------------------------------------------

            if decision.action == "error" then
                -- USER DATA CONFLICT
                -- Return structured failure instead of crashing
                return nil, {
                    kind    = "order_field_conflict",
                    stage   = "order_context_resolve",
                    field   = field,
                    values  = values,
                    message = decision.signal and decision.signal.message
                        or ("Conflicting order field '%s' with multiple distinct values."):format(field),
                    signals = signals,
                    decisions = decisions,
                }

            elseif decision.action == "defer_recalc_drop_field" then
                -- intentional drop

            elseif decision.action == "keep_first" then
                resolved_order[field] = values[1]

            elseif decision.action == "keep" then
                resolved_order[field] = values[1]

            elseif decision.action == "drop" then
                -- explicit drop

            else
                -- This is a programmer bug, not user input
                error(
                    "order_context: unknown decision action: " ..
                    tostring(decision.action)
                )
            end
        end
    end

    ------------------------------------------------------------
    -- Success
    ------------------------------------------------------------

    return {
        order     = resolved_order,
        signals   = signals,
        decisions = decisions,
    }
end

return ResolveGroup
