-- format/pipelines/decode.lua
--
-- Pipeline: codec -> canonical objects
--
-- Responsibilities:
--   • Lookup decoder from registry
--   • Run decoder
--   • Guard canonical shape
--   • Apply canonical hygiene
--   • Return { codec="objects", data=objects }
--
-- Forbidden here:
--   • Trace
--   • Contracts
--   • Cross-module orchestration

local Registry = require("format.registry")

local Decode = {}

--- Decode raw codec data into canonical objects.
---@param codec string
---@param data any
---@return table|nil out
---@return string|nil err
function Decode.run(codec, data)
    local decoder = Registry.decode[codec]
    if not decoder then
        return nil, "no decoder registered for codec '" .. tostring(codec) .. "'"
    end

    local objects, decode_err = decoder.run(data)
    if not objects then
        return nil, decode_err
    end

    local Shape = Registry.validate.shape
    if not Shape.objects(objects) then
        return nil, "decoder produced invalid canonical object shape"
    end

    Registry.normalize.clean.apply("objects", objects)

    return {
        codec = "objects",
        data  = objects,
    }
end

return Decode
