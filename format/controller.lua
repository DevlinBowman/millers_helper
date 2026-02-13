-- format/controller.lua
--
-- Canonical hub mapping surface.
--
-- Public API:
--   decode(codec, data)   → { codec="objects", data }
--   encode(codec, objects) → { codec, data }
--
-- Boundary owns contracts + trace only.

local Registry = require("format.registry")

local Trace    = require("tools.trace")
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
            data = true,
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
-- Decode (codec → objects)
----------------------------------------------------------------

function Controller.decode(codec, data)

    Trace.contract_enter("format.controller.decode")
    Trace.contract_in(Controller.CONTRACT.decode.in_)

    Contract.assert(
        { codec = codec, data = data },
        Controller.CONTRACT.decode.in_
    )

    ----------------------------------------------------------------
    -- Decoder lookup
    ----------------------------------------------------------------

    local decoder = Registry.decode[codec]
    if not decoder then
        Trace.contract_leave()
        return nil, "no decoder registered for codec '" .. codec .. "'"
    end

    ----------------------------------------------------------------
    -- Decode to canonical objects
    ----------------------------------------------------------------

    local objects, decode_err = decoder.run(data)
    if not objects then
        Trace.contract_leave()
        return nil, decode_err
    end

    ----------------------------------------------------------------
    -- Canonical hygiene
    ----------------------------------------------------------------

    objects = Registry.normalize.clean.apply("objects", objects)

    ----------------------------------------------------------------
    -- Canonical shape guard
    ----------------------------------------------------------------

    local Shape = Registry.validate.shape
    if not Shape.objects(objects) then
        Trace.contract_leave()
        return nil, "decoder produced invalid canonical object shape"
    end

    ----------------------------------------------------------------
    -- Output envelope
    ----------------------------------------------------------------

    local out = {
        codec = "objects",
        data  = objects,
    }

    -- enforce invariant (contract only checks presence)
    assert(out.codec == "objects", "decode must return codec='objects'")

    Trace.contract_out(Controller.CONTRACT.decode.out, codec, "caller")
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

    ----------------------------------------------------------------
    -- Canonical shape guard
    ----------------------------------------------------------------

    local Shape = Registry.validate.shape
    if not Shape.objects(objects) then
        Trace.contract_leave()
        return nil, "invalid canonical objects shape"
    end

    ----------------------------------------------------------------
    -- Lookup encoder
    ----------------------------------------------------------------

    local encoder = Registry.encode[codec]

    local data
    local err

    if encoder then
        data, err = encoder.run(objects)
        if not data then
            Trace.contract_leave()
            return nil, err
        end

    elseif codec == "lua" then
        -- identity allowed
        data = objects

    else
        Trace.contract_leave()
        return nil, "no encoder registered for codec '" .. codec .. "'"
    end

    ----------------------------------------------------------------
    -- Output envelope
    ----------------------------------------------------------------

    local out = {
        codec = codec,
        data  = data,
    }

    Trace.contract_out(Controller.CONTRACT.encode.out, codec, "caller")
    Contract.assert(out, Controller.CONTRACT.encode.out)
    Trace.contract_leave()

    return out
end

return Controller
