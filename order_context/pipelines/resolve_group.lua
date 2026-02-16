-- order_context/pipelines/resolve_group.lua
--
-- Resolve one order group into coherent order context.
-- Composes util + policy.
-- No contracts. No tracing.

local Registry = require("order_context.registry")

local ResolveGroup = {}

--- @param rows table[]
--- @param opts table|nil
--- @return table { order=table, signals=table[], decisions=table }
function ResolveGroup.run(rows, opts)
    opts                 = opts or {}

    local Util           = Registry.util
    local Policy         = Registry.policy

    local resolved_order = {}
    local signals        = {}
    local decisions      = {}

    local fields         = Util.collect_order_fields(rows)

    for _, field in ipairs(fields) do
        local field_spec = Registry.spec.fields[field] or Registry.spec.default

        local normalizer = nil
        if field_spec.normalize then
            normalizer = Util[field_spec.normalize]
        end

        local values = Util.collect_order_field_values(rows, field, normalizer)

        if #values == 0 then
            -- nothing
        elseif #values == 1 then
            resolved_order[field] = values[1]
            decisions[field] = { action = "keep", value = values[1] }
        else
            local decision = Policy.decide(field, values, rows, opts)

            decisions[field] = {
                action = decision.action,
                values = values,
            }

            if decision.signal then
                signals[#signals + 1] = decision.signal
            end

            if decision.action == "error" then
                error(
                    decision.signal and decision.signal.message
                    or ("order_context conflict on field: " .. tostring(field))
                )
            elseif decision.action == "defer_recalc_drop_field" then
                -- omit field; builder recalculates
            elseif decision.action == "keep_first" then
                resolved_order[field] = values[1]
            elseif decision.action == "keep" then
                resolved_order[field] = values[1]
            elseif decision.action == "drop" then
                -- explicitly omitted
            else
                error("order_context: unknown decision action: " .. tostring(decision.action))
            end
        end
    end

    return {
        order     = resolved_order,
        signals   = signals,
        decisions = decisions,
    }
end

return ResolveGroup
