-- format/controller.lua
--
-- Canonical hub mapping surface.
--
-- Public API:
--   decode(codec, data)    → { codec="objects", data }
--   encode(codec, objects) → { codec, data }
--
-- Boundary owns contracts + trace only.

local Registry        = require("platform.format.registry")
local DecodePipeline  = require("platform.format.pipelines.decode")
local EncodePipeline  = require("platform.format.pipelines.encode")

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {

    decode = {
        in_ = {
            codec = true,
            data  = true,
        },
        out = {
            codec = true,
            data  = true,
        },
    },

    encode = {
        in_ = {
            codec   = true,
            objects = true,
        },
        out = {
            codec = true,
            data  = true,
        },
    },
}

----------------------------------------------------------------
-- Decode (codec → canonical objects)
----------------------------------------------------------------

function Controller.decode(codec, data)

    Trace.contract_enter("format.controller.decode")
    Trace.contract_in(Controller.CONTRACT.decode.in_)

    Contract.assert(
        { codec = codec, data = data },
        Controller.CONTRACT.decode.in_
    )

    local out, err = DecodePipeline.run(codec, data)
    if not out then
        Trace.contract_leave()
        return nil, err
    end

    Trace.contract_out(
        Controller.CONTRACT.decode.out,
        codec,
        "caller"
    )

    Contract.assert(out, Controller.CONTRACT.decode.out)

    Trace.contract_leave()
    return out
end

----------------------------------------------------------------
-- Encode (objects → codec)
----------------------------------------------------------------

function Controller.encode(codec, objects)

    Trace.contract_enter("format.controller.encode")
    Trace.contract_in(Controller.CONTRACT.encode.in_)

    Contract.assert(
        { codec = codec, objects = objects },
        Controller.CONTRACT.encode.in_
    )

    local out, err = EncodePipeline.run(codec, objects)
    if not out then
        Trace.contract_leave()
        return nil, err
    end

    Trace.contract_out(
        Controller.CONTRACT.encode.out,
        codec,
        "caller"
    )

    Contract.assert(out, Controller.CONTRACT.encode.out)

    Trace.contract_leave()
    return out
end

return Controller
