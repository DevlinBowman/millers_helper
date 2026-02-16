-- order_context/internal/policy.lua
--
-- Spec-driven conflict resolution engine.
-- Pure logic.

local Util   = require("order_context.internal.util")
local Signal = require("order_context.internal.signal")
local Spec   = require("order_context.internal.spec")

local Policy = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function get_field_spec(field)
    return Spec.fields[field] or Spec.default
end

local function build_error(field, values)
    return {
        action = "error",
        signal = Signal.new({
            kind       = "order_field_conflict",
            severity   = "error",
            field      = field,
            values     = values,
            resolution = "error",
            message    = ("conflicting order field '%s': %s")
                :format(field, table.concat(values, ", ")),
        }),
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Decide resolution strategy for a conflicting field.
--- @param field string
--- @param values string[]
--- @param rows table[]
--- @param opts table|nil
--- @return table decision { action=string, signal=table|nil }
function Policy.decide(field, values, rows, opts)
    opts = opts or {}

    local spec = get_field_spec(field)

    if spec.conflict == "strict" then
        return build_error(field, values)
    end

    if spec.conflict == "keep_first" then
        return {
            action = "keep_first",
            signal = Signal.new({
                kind       = "order_field_keep_first",
                severity   = "warn",
                field      = field,
                values     = values,
                resolution = "keep_first",
                message    = ("conflicting field '%s'; keeping first value")
                    :format(field),
            }),
        }
    end

    if spec.conflict == "recalculable" then

        local numeric_values = {}
        local has_non_numeric = false

        for _, v in ipairs(values) do
            if Util.is_numeric(v) then
                numeric_values[#numeric_values + 1] = tonumber(v)
            else
                has_non_numeric = true
            end
        end

        if #numeric_values > 1 then
            return build_error(field, values)
        end

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
                        message    =
                            ("non-numeric token for '%s'; dropping for recalculation")
                            :format(field),
                    }),
                }
            end
        end

        if #numeric_values == 1 then
            return { action = "keep" }
        end

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
                        message    =
                            ("conflicting '%s'; dropping for recalculation")
                            :format(field),
                    }),
                }
            end
        end

        return build_error(field, values)
    end

    error("order_context.policy: unknown conflict type for field '" .. field .. "'")
end


return Policy
