-- core/model/order/internal/coerce.lua

local Schema = require("core.model.order.internal.schema")

local Coerce = {}

--- Coerce order inputs according to schema roles.
--- Authoritative fields: strict coercion (error on failure)
--- Derived fields: best-effort coercion (no hard error)
---
--- @param ctx table
--- @return table coerced
--- @return table unknown
function Coerce.run(ctx)
    assert(type(ctx) == "table", "Order.coerce(): ctx table required")

    local out     = {}
    local unknown = {}

    for key, value in pairs(ctx) do
        local def = Schema.fields[key]

        --------------------------------------------------------
        -- Known schema field
        --------------------------------------------------------

        if def then

            ----------------------------------------------------
            -- AUTHORITATIVE (strict)
            ----------------------------------------------------

            if def.role == Schema.ROLES.AUTHORITATIVE then

                if value ~= nil and def.coerce then
                    local coerced = def.coerce(value)

                    if coerced == nil and value ~= nil then
                        error(
                            "Order.coerce(): failed coercion for field '" .. key .. "'"
                        )
                    end

                    out[key] = coerced
                else
                    out[key] = value
                end

            ----------------------------------------------------
            -- DERIVED (lenient)
            ----------------------------------------------------

            elseif def.role == Schema.ROLES.DERIVED then

                if value ~= nil and def.coerce then
                    -- Attempt coercion but NEVER error
                    out[key] = def.coerce(value)
                else
                    out[key] = value
                end

            else
                -- Unknown role → programmer error
                error(
                    "Order.coerce(): unknown role for field '" .. key .. "'"
                )
            end

        --------------------------------------------------------
        -- Unknown field
        --------------------------------------------------------

        else
            unknown[key] = value
        end
    end

    return out, unknown
end

return Coerce
