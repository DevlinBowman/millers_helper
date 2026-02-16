-- core/model/board/internal/coerce.lua

local Schema    = require("core.model.board.internal.schema")
local Normalize = require("core.model.board.internal.normalize")

local Coerce = {}

--- Coerce authoritative board inputs.
--- Returns a single flat result table:
--- {
---     value   = coerced_table,
---     unknown = unknown_table,
--- }
---
--- @param ctx table
--- @return table
function Coerce.run(ctx)
    assert(type(ctx) == "table", "Board.coerce(): ctx table required")

    local coerced = {}
    local unknown = {}

    ------------------------------------------------------------
    -- Field coercion
    ------------------------------------------------------------

    for key, value in pairs(ctx) do
        local field_def = Schema.fields[key]

        if field_def and field_def.role == Schema.ROLES.AUTHORITATIVE then
            if value ~= nil and field_def.coerce then
                local coerced_value = field_def.coerce(value)

                if coerced_value == nil and value ~= nil then
                    error("Board.coerce(): failed coercion for field '" .. key .. "'")
                end

                coerced[key] = coerced_value
            else
                coerced[key] = value
            end
        else
            unknown[key] = value
        end
    end

    ------------------------------------------------------------
    -- Default count
    ------------------------------------------------------------

    coerced.ct = coerced.ct or 1

    ------------------------------------------------------------
    -- Intelligent tag assignment (n vs c)
    ------------------------------------------------------------

    if coerced.tag == nil or coerced.tag == "" then
        local nominal_map = Normalize.NOMINAL_FACE_MAP
        local base_h      = coerced.base_h
        local base_w      = coerced.base_w

        local is_nominal_h = nominal_map[base_h] ~= nil
        local is_nominal_w = nominal_map[base_w] ~= nil

        if is_nominal_h and is_nominal_w then
            coerced.tag = "n"
        else
            coerced.tag = "c"
        end
    end

    ------------------------------------------------------------
    -- Validate allowed tags
    ------------------------------------------------------------

    if coerced.tag ~= "n"
        and coerced.tag ~= "f"
        and coerced.tag ~= "c"
    then
        error("Board.coerce(): invalid tag '" .. tostring(coerced.tag) .. "'")
    end

    ------------------------------------------------------------
    -- Flat single return
    ------------------------------------------------------------

    return {
        value   = coerced,
        unknown = unknown,
    }
end

return Coerce
