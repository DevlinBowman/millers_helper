-- platform/persist/controller.lua
--
-- Public boundary surface for canonical persistence.

local Pipeline   = require("platform.persist.pipelines.write")
local Trace      = require("tools.trace.trace")
local Contract   = require("core.contract")
local Diagnostic = require("tools.diagnostic")

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {
    write = {
        in_ = {
            path  = true,
            value = true,
            codec = false,
            opts  = false,
        },
        out = {
            path       = true,
            ext        = true,
            size_bytes = true,
            hash       = true,
            write_time = true,
        },
    },
}

----------------------------------------------------------------
-- Write (RELAXED)
----------------------------------------------------------------

function Controller.write(path, value, codec, opts)
    Trace.contract_enter("persist.controller.write")
    Trace.contract_in({ path = path, value = value, codec = codec })

    Contract.assert(
        { path = path, value = value, codec = codec, opts = opts },
        Controller.CONTRACT.write.in_
    )

    Diagnostic.scope_enter("persist.controller.write")
    Diagnostic.debug("persist.path", path)
    Diagnostic.debug("persist.codec", codec or "json")

    local meta, err = Pipeline.run(path, value, codec, opts)

    if not meta then
        Diagnostic.user_message(err or "persist failed", "error")
        Diagnostic.scope_leave()
        Trace.contract_leave()
        return nil, err
    end

    Contract.assert(meta, Controller.CONTRACT.write.out)
    Trace.contract_out(meta, "persist.write", "caller")

    Diagnostic.scope_leave()
    Trace.contract_leave()

    return meta
end

----------------------------------------------------------------
-- Write (STRICT)
----------------------------------------------------------------

function Controller.write_strict(path, value, codec, opts)
    local meta, err = Controller.write(path, value, codec, opts)
    if not meta then
        error(err, 2)
    end
    return meta
end

return Controller
