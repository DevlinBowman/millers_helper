-- core/model/board/internal/coerce.lua

local Schema    = require("core.model.board.internal.schema")
local Normalize = require("core.model.board.internal.normalize")

local Coerce = {}

--- Coerce authoritative board inputs and return unknown inputs separately.
--- Unknowns are ONLY from the incoming ctx/spec (not derived fields computed later).
---
--- @param ctx table
--- @return table coerced
--- @return table unknown
function Coerce.run(ctx)
    assert(type(ctx) == "table", "Board.coerce(): ctx table required")

    local out     = {}
    local unknown = {}

    for k, v in pairs(ctx) do
        local def = Schema.fields[k]

        if def and def.role == Schema.ROLES.AUTHORITATIVE then
            if v ~= nil and def.coerce then
                local coerced = def.coerce(v)
                if coerced == nil and v ~= nil then
                    error("Board.coerce(): failed coercion for field '" .. k .. "'")
                end
                out[k] = coerced
            else
                out[k] = v
            end
        else
            unknown[k] = v
        end
    end

    -- Default count
    out.ct = out.ct or 1

    ------------------------------------------------------------
    -- Intelligent tag assignment (n vs c vs f)
    ------------------------------------------------------------
    if out.tag == nil or out.tag == "" then
        local nominal_map = Normalize.NOMINAL_FACE_MAP
        local base_h = out.base_h
        local base_w = out.base_w

        local h_nominal = nominal_map[base_h] ~= nil
        local w_nominal = nominal_map[base_w] ~= nil

        if h_nominal and w_nominal then
            out.tag = "n"
        else
            out.tag = "c"
        end
    end

    ------------------------------------------------------------
    -- Validate allowed tags
    ------------------------------------------------------------
    if out.tag ~= "n" and out.tag ~= "f" and out.tag ~= "c" then
        error("Board.coerce(): invalid tag '" .. tostring(out.tag) .. "'")
    end

    return out, unknown
end

return Coerce
