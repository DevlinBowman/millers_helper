-- core/model/board/coerce.lua

local Schema = require("core.model.board.schema")

local Coerce = {}

function Coerce.run(ctx)
    local out = {}

    for field, def in pairs(Schema.fields) do
        if def.role == Schema.ROLES.AUTHORITATIVE then
            local v = ctx[field]
            if v ~= nil and def.coerce then
                local coerced = def.coerce(v)
                if coerced == nil and v ~= nil then
                    error("Board.coerce(): failed coercion for field '" .. field .. "'")
                end
                out[field] = coerced
            else
                out[field] = v
            end
        end
    end

    out.ct = out.ct or 1
    return out
end

return Coerce
