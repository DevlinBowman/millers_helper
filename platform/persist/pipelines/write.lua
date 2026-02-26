-- platform/persist/pipelines/write.lua
--
-- Canonical persistence pipeline: encode -> write
-- No tracing. No contracts. No validation.

local Registry = require("platform.persist.registry")

local Write = {}

function Write.run(path, value, codec, opts)
    codec = codec or "json"
    opts  = opts  or {}

    ------------------------------------------------------------
    -- Encode
    ------------------------------------------------------------

    local encoded, encode_err = Registry.format.encode(codec, value, opts)
    if not encoded then
        return nil, encode_err
    end

    ------------------------------------------------------------
    -- Write
    ------------------------------------------------------------

    local meta, write_err = Registry.io.write(path, encoded)
    if not meta then
        return nil, write_err
    end

    return meta
end

return Write
