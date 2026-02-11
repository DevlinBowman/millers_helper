-- io/controller.lua
--
-- Public IO control surface.
-- Pure IO: no formatting, no normalization, no semantic helpers.

local Registry = require("io.registry")
local Validate = Registry.validate.input

local Controller = {}

----------------------------------------------------------------
-- Read (RELAXED)
----------------------------------------------------------------

--- Read a file and return raw codec output.
---@param path string
---@return table|nil result
---@return string|nil err
function Controller.read(path)
    local ok, err = Validate.read({
        mode   = "read",
        source = { kind = "path", value = path },
    })
    if not ok then
        return nil, err
    end

    return Registry.read.read(path)
end

----------------------------------------------------------------
-- Write (RELAXED)
----------------------------------------------------------------

--- Write already-formatted payload.
---@param path string
---@param payload table
---@return table|nil meta
---@return string|nil err
function Controller.write(path, payload)
    local ok, err = Validate.write({
        mode   = "write",
        source = { kind = "path", value = path },
        data   = payload,
    })
    if not ok then
        return nil, err
    end

    return Registry.write.write(path, payload)
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
