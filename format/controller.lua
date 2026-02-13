-- format/controller.lua
--
-- Structural codec conversion controller.
-- Boundary only.
-- Owns contracts + trace.
-- Delegates orchestration to system.converter.

local Registry  = require("format.registry")
local Converter = require("format.system.converter")

local Trace     = require("tools.trace")
local Contract  = require("core.contract")

local Controller = {}

----------------------------------------------------------------
-- Contract Definition
----------------------------------------------------------------

Controller.CONTRACT = {
    convert = {
        in_ = {
            payload = {
                codec = true,
                data  = true,
            },
            target_codec = true,
        },

        out = {
            codec = true,
            data  = true,
        },
    },
}

----------------------------------------------------------------
-- Internal guards
----------------------------------------------------------------

local function assert_string(value, name)
    if type(value) ~= "string" or value == "" then
        error("invalid " .. name .. " (expected non-empty string)", 3)
    end
end

----------------------------------------------------------------
-- Convert (RELAXED)
----------------------------------------------------------------

---@param payload { codec:string, data:any }
---@param target_codec string
---@return { codec:string, data:any }|nil
---@return string|nil err
function Controller.convert(payload, target_codec)

    Trace.contract_enter("format.controller.convert")
    Trace.contract_in(Controller.CONTRACT.convert.in_)

    Contract.assert(
        { payload = payload, target_codec = target_codec },
        Controller.CONTRACT.convert.in_
    )

    -- Guard: codec sanity
    assert_string(payload.codec, "payload.codec")
    assert_string(target_codec, "target_codec")

    -- Guard: avoid meaningless self-call
    if payload.codec == target_codec then
        Trace.contract_out(
            Controller.CONTRACT.convert.out,
            "identity",
            "caller"
        )
        Trace.contract_leave()
        return payload
    end

    local result, err = Converter.run(payload, target_codec)
    if not result then
        Trace.contract_leave()
        return nil, err
    end

    -- Guard: ensure converter honored target
    if result.codec ~= target_codec then
        Trace.contract_leave()
        return nil,
            "converter returned mismatched codec: expected '" ..
            target_codec .. "', got '" .. tostring(result.codec) .. "'"
    end

    Trace.contract_out(
        Controller.CONTRACT.convert.out,
        payload.codec .. "_to_" .. target_codec,
        "caller"
    )

    Contract.assert(result, Controller.CONTRACT.convert.out)

    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- STRICT
----------------------------------------------------------------

function Controller.convert_strict(payload, target_codec)
    local result, err = Controller.convert(payload, target_codec)
    if not result then
        error(err, 2)
    end
    return result
end

return Controller
