local Schema = require("core.model.order.schema")

local Coerce = {}

function Coerce.run(ctx)
    local out = {}

    for field, def in pairs(Schema.fields) do
        local v = ctx[field]

        if v ~= nil and def.coerce then
            local coerced = def.coerce(v)
            if coerced == nil and v ~= nil then
                error("Order.coerce(): failed coercion for field '" .. field .. "'")
            end
            out[field] = coerced
        else
            out[field] = v
        end
    end

    return out
end

return Coerce
