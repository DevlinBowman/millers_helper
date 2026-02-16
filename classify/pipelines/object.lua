-- classify/pipelines/object.lua
--
-- Classification behavior pipeline.
-- Composes alias + partition primitives into domain partitions.
-- Operates on a single decoded object (flat attribute map).

local Registry = require("classify.registry")

local Object = {}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Object.run(object)
    assert(type(object) == "table", "classify.pipelines.object: table required")

    local alias = Registry.alias
    local part  = Registry.partition
    local spec  = Registry.spec

    local out = {
        board       = {},
        order       = {},
        unknown     = {},
        diagnostics = {
            overwrites = nil,
            collisions = nil,
        },
    }

    for raw_key, value in pairs(object) do
        local canonical = alias.resolve(raw_key)

        if not canonical then
            out.unknown[raw_key] = value
        else
            local owner = part.owner_of(canonical)

            if owner == spec.DOMAIN.BOARD then
                part.set_field(out.board, canonical, value, out.diagnostics, tostring(raw_key))

            elseif owner == spec.DOMAIN.ORDER then
                part.set_field(out.order, canonical, value, out.diagnostics, tostring(raw_key))

            else
                out.unknown[raw_key] = value
            end
        end
    end

    local collisions = alias.collisions()
    if next(collisions) ~= nil then
        out.diagnostics.collisions = collisions
    end

    return out
end

return Object
