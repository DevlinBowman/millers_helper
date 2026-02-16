-- classify/internal/partition.lua
--
-- Pure internal partition primitives.
-- No tracing. No registry. No orchestration.
--
-- Exposes:
--   • owner_of(canonical)
--   • set_field(dst, canonical, value, diagnostics, raw_key)

local Spec = require("classify.internal.schema")

local Partition = {}

----------------------------------------------------------------
-- Helpers (public primitives)
----------------------------------------------------------------

---@param canonical string|nil
---@return string|nil
function Partition.owner_of(canonical)
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

---@param dst table
---@param canonical string
---@param value any
---@param diagnostics table
---@param raw_key string
function Partition.set_field(dst, canonical, value, diagnostics, raw_key)
    if dst[canonical] ~= nil then
        diagnostics.overwrites = diagnostics.overwrites or {}
        diagnostics.overwrites[#diagnostics.overwrites + 1] = {
            canonical = canonical,
            from_key  = raw_key,
        }
    end

    dst[canonical] = value
end

return Partition
