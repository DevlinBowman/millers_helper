-- classify/pipelines/row.lua
--
-- Classification behavior pipeline.
-- Composes alias + partition primitives into domain partitions.

local Registry = require("classify.registry")

local Row = {}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Row.run(row)
    assert(type(row) == "table", "classify.pipelines.row: row table required")

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

    for raw_key, value in pairs(row) do
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

return Row
