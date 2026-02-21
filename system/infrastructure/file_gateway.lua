-- system/infrastructure/file_gateway.lua
--
-- Unified file write gateway.
-- Wraps platform.io.controller.
-- Infrastructure layer only.

local IO = require("platform.io.controller")

local FileGateway = {}

------------------------------------------------------------
-- JSON
------------------------------------------------------------

function FileGateway.write_json(path, data)
    print('[WRITE] FileGateway.write_json @ ', path)
    return IO.write(path, {
        codec = "json",
        data  = data,
    })
end

function FileGateway.read_json(path)
    print('[WRITE] FileGateway.read_json @ ', path)
    local result, err = IO.read(path)
    if not result then
        return nil, err
    end

    return result.data
end

------------------------------------------------------------
-- Delimited
------------------------------------------------------------

function FileGateway.write_delimited(path, objects)
    print('[WRITE] FileGateway.write_delimited @ ', path)

    return IO.write(path, {
        codec = "delimited",
        data  = objects,
    })
end

------------------------------------------------------------
-- Raw (explicit codec)
------------------------------------------------------------

function FileGateway.write(path, codec, data)
    assert(type(codec) == "string", "codec required")
    print('[WRITE] FileGateway.write @ ', path)
    return IO.write(path, {
        codec = codec,
        data  = data,
    })
end

------------------------------------------------------------
-- Generic Read
------------------------------------------------------------

function FileGateway.read(path)
    assert(type(path) == "string" and path ~= "", "path required")
    print('[READ] FileGateway.read@ ', path)
    local result, err = IO.read(path)
    if not result then
        return nil, err
    end

    return result
end

return FileGateway
