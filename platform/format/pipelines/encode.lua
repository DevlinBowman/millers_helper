-- format/pipelines/encode.lua
--
-- Pipeline: canonical objects -> codec
--
-- Responsibilities:
--   • Guard canonical shape
--   • Lookup encoder from registry
--   • Run encoder (or allow identity for lua)
--   • Return { codec=<codec>, data=<data> }
--
-- Forbidden here:
--   • Trace
--   • Contracts
--   • Cross-module orchestration

local Registry = require("platform.format.registry")

local Encode = {}

--- Encode canonical objects into target codec.
---@param codec string
---@param objects table
---@return table|nil out
---@return string|nil err
function Encode.run(codec, objects)
    local Shape = Registry.validate.shape
    if not Shape.objects(objects) then
        return nil, "invalid canonical objects shape"
    end

    local encoder = Registry.encode[codec]
    local data
    local err

    if encoder then
        data, err = encoder.run(objects)
        if not data then
            return nil, err
        end
    elseif codec == "lua" then
        data = objects
    else
        return nil, "no encoder registered for codec '" .. tostring(codec) .. "'"
    end

    return {
        codec = codec,
        data  = data,
    }
end

return Encode
