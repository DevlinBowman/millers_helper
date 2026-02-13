-- io/controller.lua
--
-- Public IO control surface.
-- Pure IO: no formatting, no normalization, no semantic helpers.
-- Uses global runtime debug tracer.
-- Enforces structural contracts at boundary (IN + OUT).

local Registry      = require("io.registry")
local Validate      = Registry.validate.input
local FS            = Registry.fs

local Trace         = require("tools.trace")
local Contract      = require("core.contract")

local Controller    = {}

----------------------------------------------------------------
-- Contract Definition (Boundary Shape)
----------------------------------------------------------------

Controller.CONTRACT = {
    read = {
        in_ = {
            path = true,
        },

        out = {
            codec = true,
            data  = true,
            meta  = {
                source_path = true,
                input_codec = true,
                size_bytes  = true,
                hash        = true,
                read_time   = true,
            },
        },
    },

    write = {
        in_ = {
            path    = true,
            payload = true
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
-- Internal normalization
----------------------------------------------------------------

local function normalize_read_envelope(path, result)
    assert(type(result) == "table", "invalid read result")
    assert(result.codec ~= nil, "read result missing codec")
    assert(result.data ~= nil, "read result missing data")

    result.meta = {
        source_path = path,
        input_codec = result.codec,
        size_bytes  = FS.file_size(path),
        hash        = FS.file_hash(path),
        read_time   = os.date("%Y-%m-%d %H:%M:%S"),
    }

    return result
end

----------------------------------------------------------------
-- Read (RELAXED)
----------------------------------------------------------------

function Controller.read(path)
    Trace.contract_enter("io.controller.read")
    Trace.contract_in(Controller.CONTRACT.read.in_)
    Contract.assert({ path = path }, Controller.CONTRACT.read.in_)

    local ok, err = Validate.read({
        mode   = "read",
        source = { kind = "path", value = path },
    })
    if not ok then
        Trace.contract_leave()
        return nil, err
    end

    local result, read_err = Registry.read.read(path)
    if not result then
        Trace.contract_leave()
        return nil, read_err
    end

    result = normalize_read_envelope(path, result)

    Trace.contract_out(Controller.CONTRACT.read.out, "registry.read", "caller")
    Contract.assert(result, Controller.CONTRACT.read.out)

    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- Write (RELAXED)
----------------------------------------------------------------

function Controller.write(path, payload)
    Trace.contract_enter("io.controller.write")
    Trace.contract_in(Controller.CONTRACT.write.in_)
    Contract.assert(
        { path = path, payload = payload },
        Controller.CONTRACT.write.in_
    )

    local ok, err = Validate.write({
        mode   = "write",
        source = { kind = "path", value = path },
        data   = payload,
    })
    if not ok then
        Trace.contract_leave()
        return nil, err
    end

    local meta, write_err = Registry.write.write(path, payload)
    if not meta then
        Trace.contract_leave()
        return nil, write_err
    end

    Trace.contract_out(Controller.CONTRACT.write.out, "registry.write", "caller")
    Contract.assert(meta, Controller.CONTRACT.write.out)

    Trace.contract_leave()

    return meta
end

----------------------------------------------------------------
-- STRICT variants
----------------------------------------------------------------

function Controller.read_strict(path)
    local result, err = Controller.read(path)
    if not result then
        error(err, 2)
    end
    return result
end

function Controller.write_strict(path, payload)
    local meta, err = Controller.write(path, payload)
    if not meta then
        error(err, 2)
    end
    return meta
end

----------------------------------------------------------------
-- Streaming utility
----------------------------------------------------------------

function Controller.stream(iter, sink)
    assert(type(iter) == "function", "iter must be function")
    assert(type(sink) == "table" and sink.write, "sink must support :write()")

    while true do
        local v = iter()
        if v == nil then break end
        sink:write(v)
    end

    return true
end

return Controller
