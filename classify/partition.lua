-- classify/partition.lua
--
-- Takes:
--   - raw decoded object (table)
-- Outputs:
--   - board:   canonical fields (board-owned)
--   - order:   canonical fields (order-owned)
--   - unknown: passthrough raw keys that did not resolve or did not map to an owner
--   - meta:    diagnostics (collisions, overwrites)

local Registry = require("classify.registry")
local Alias    = require("classify.alias")

local Partition = {}

local function set_field(dst, canonical, value, meta, raw_key)
    if dst[canonical] ~= nil then
        meta.overwrites = meta.overwrites or {}
        meta.overwrites[#meta.overwrites + 1] = {
            canonical = canonical,
            from_key  = raw_key,
        }
    end
    dst[canonical] = value
end

function Partition.run(row)
    assert(type(row) == "table", "classify.partition: row table required")

    local out = {
        board   = {},
        order   = {},
        unknown = {},
        meta    = {
            overwrites = nil,
            collisions = nil,
        },
    }

    for raw_key, value in pairs(row) do
        local canonical = Alias.resolve(raw_key)
        if not canonical then
            out.unknown[raw_key] = value
        else
            local owner = Registry.owner_of(canonical)
            if owner == "board" then
                set_field(out.board, canonical, value, out.meta, raw_key)
            elseif owner == "order" then
                set_field(out.order, canonical, value, out.meta, raw_key)
            else
                out.unknown[raw_key] = value
            end
        end
    end

    local collisions = Alias.collisions()
    if next(collisions) ~= nil then
        out.meta.collisions = collisions
    end

    return out
end

return Partition
