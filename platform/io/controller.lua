-- platform/io/controller.lua
--
-- Public IO control surface.
-- Pure IO: no formatting, no normalization, no semantic helpers.
-- Uses global runtime debug tracer.
-- Enforces structural contracts at boundary (IN + OUT).
--
-- Diagnostic Layer:
--   • Scoped runtime diagnostics
--   • No pollution of canonical envelope
--   • Exported only if opts.include_diagnostics == true

local Registry      = require("platform.io.registry")
local Validate      = Registry.validate.input
local FS            = Registry.fs

local Trace         = require("tools.trace.trace")
local Diagnostic    = require("tools.diagnostic")
local Contract      = require("core.contract")

local Controller    = {}

----------------------------------------------------------------
-- Contract Definition (Boundary Shape)
----------------------------------------------------------------

Controller.CONTRACT = {
    read = {
        in_ = {
            path = true,
            opts = false,
        },

        out = {
            codec = true,
            data  = true,
            meta  = true,
        },
    },

    write = {
        in_ = {
            path    = true,
            payload = true,
            opts    = false,
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

    result.meta = result.meta or {}

    result.meta.io = {
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

function Controller.read(path, opts)
    opts = opts or {}
    local include_diag = opts.include_diagnostics == true

    Trace.contract_enter("io.controller.read")
    Trace.contract_in({ path = path })

    Contract.assert({ path = path, opts = opts }, Controller.CONTRACT.read.in_)

    ------------------------------------------------------------
    -- Begin Diagnostic Scope (Vertical Plane)
    ------------------------------------------------------------

    Diagnostic.scope_enter("io.controller.read")

    Diagnostic.debug("read.path", path)

    local ok, err = Validate.read({
        mode   = "read",
        source = { kind = "path", value = path },
    })

    if not ok then
        Diagnostic.user_message(err or "invalid read input", "error")
        local scope = Diagnostic.scope_leave()
        Trace.contract_leave()

        if include_diag then
            return nil, err, scope
        end

        return nil, err
    end

    local result, read_err = Registry.read.read(path)

    if not result then
        Diagnostic.user_message(read_err or "registry read failed", "error")
        local scope = Diagnostic.scope_leave()
        Trace.contract_leave()

        if include_diag then
            return nil, read_err, scope
        end

        return nil, read_err
    end

    result = normalize_read_envelope(path, result)

    Diagnostic.debug("read.codec", result.codec)
    Diagnostic.debug("read.meta.io", result.meta.io)

    Trace.contract_out(result, "registry.read", "caller")
    Contract.assert(result, Controller.CONTRACT.read.out)

    ------------------------------------------------------------
    -- Close Diagnostic Scope
    ------------------------------------------------------------

    local scope = Diagnostic.scope_leave()

    Trace.contract_leave()

    if include_diag then
        return result, nil, scope
    end

    return result
end

----------------------------------------------------------------
-- Write (RELAXED)
----------------------------------------------------------------

function Controller.write(path, payload, opts)
    opts = opts or {}
    local include_diag = opts.include_diagnostics == true

    Trace.contract_enter("io.controller.write")
    Trace.contract_in({ path = path, payload = payload })

    Contract.assert(
        { path = path, payload = payload, opts = opts },
        Controller.CONTRACT.write.in_
    )

    Diagnostic.scope_enter("io.controller.write")

    Diagnostic.debug("write.path", path)

    local ok, err = Validate.write({
        mode   = "write",
        source = { kind = "path", value = path },
        data   = payload,
    })

    if not ok then
        Diagnostic.user_message(err or "invalid write input", "error")
        local scope = Diagnostic.scope_leave()
        Trace.contract_leave()

        if include_diag then
            return nil, err, scope
        end

        return nil, err
    end

    local meta, write_err = Registry.write.write(path, payload)

    if not meta then
        Diagnostic.user_message(write_err or "registry write failed", "error")
        local scope = Diagnostic.scope_leave()
        Trace.contract_leave()

        if include_diag then
            return nil, write_err, scope
        end

        return nil, write_err
    end

    Diagnostic.debug("write.meta", meta)

    Trace.contract_out(meta, "registry.write", "caller")
    Contract.assert(meta, Controller.CONTRACT.write.out)

    local scope = Diagnostic.scope_leave()

    Trace.contract_leave()

    if include_diag then
        return meta, nil, scope
    end

    return meta
end

----------------------------------------------------------------
-- STRICT variants
----------------------------------------------------------------

function Controller.read_strict(path, opts)
    local result, err = Controller.read(path, opts)
    if not result then
        error(err, 2)
    end
    return result
end

function Controller.write_strict(path, payload, opts)
    local meta, err = Controller.write(path, payload, opts)
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

    Diagnostic.scope_enter("io.controller.stream")

    while true do
        local v = iter()
        if v == nil then break end
        Diagnostic.debug("stream.chunk", v)
        sink:write(v)
    end

    local scope = Diagnostic.scope_leave()

    return true, scope
end

return Controller
