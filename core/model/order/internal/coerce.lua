-- core/model/order/internal/coerce.lua

local Schema = require("core.model.order.internal.schema")

local Coerce = {}

--- Coerce authoritative order inputs and return unknown inputs separately.
--- @param ctx table
--- @return table coerced
--- @return table unknown
function Coerce.run(ctx)
    assert(type(ctx) == "table", "Order.coerce(): ctx table required")

    local out     = {}
    local unknown = {}

    for k, v in pairs(ctx) do
        local def = Schema.fields[k]
        if def and def.role == Schema.ROLES.AUTHORITATIVE then
            if v ~= nil and def.coerce then
                local coerced = def.coerce(v)
                if coerced == nil and v ~= nil then
                    error("Order.coerce(): failed coercion for field '" .. k .. "'")
                end
                out[k] = coerced
            else
                out[k] = v
            end
        else
            unknown[k] = v
        end
    end

    return out, unknown
end

return Coerce
