-- classify/registry.lua
--
-- Ownership registry:
--   canonical field -> domain ("board"|"order"|nil)

local Spec = require("classify.spec")

local Registry = {}

function Registry.owner_of(canonical)
    if canonical == nil then
        return nil
    end

    if Spec.board_fields[canonical] then
        return Spec.DOMAIN.BOARD
    end

    if Spec.order_fields[canonical] then
        return Spec.DOMAIN.ORDER
    end

    return nil
end

return Registry
