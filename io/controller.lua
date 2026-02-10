-- io/controller.lua
--
-- Public IO control surface.
-- This is the ONLY supported external entrypoint.
--
-- Policy:
--   • Default functions are RELAXED (return nil, err)
--   • STRICT variants throw on failure
--   • Call-site intent is explicit

local Registry = require("io.registry")

local Controller = {}

----------------------------------------------------------------
--- Read (RELAXED / backwards compatible)
----------------------------------------------------------------

--- Read a file and return the raw codec result.
---@param path string
---@return table|nil result
---@return string|nil err
function Controller.read(path)
    return Registry.read.read(path)
end

---@param path string
---@return IOTableResult|nil
---@return string|nil err
-- for if caller expects tabular data
function Controller.read_table(path)
    local result, err = Registry.read.read(path)
    if not result then
        return nil, err
    end

    if result.kind ~= "table" then
        return nil, "expected table input"
    end

    return result
end

----------------------------------------------------------------
-- Read + normalize (RELAXED)
----------------------------------------------------------------

--- Read a file and normalize into records when possible.
---@param path string
---@return table|nil records
---@return string|nil err
function Controller.read_records(path)
    local result, err = Registry.read.read(path)
    if not result then
        return nil, err
    end

    if result.kind == "table" then
        return Registry.normalize.table(result)
    elseif result.kind == "json" then
        return Registry.normalize.json(result)
    else
        return nil, "unsupported normalization kind: " .. tostring(result.kind)
    end
end

----------------------------------------------------------------
-- Write (RELAXED / backwards compatible)
----------------------------------------------------------------

--- Write structured data to disk.
---@param path string
---@param kind string
---@param data any
---@return table|nil meta
---@return string|nil err
function Controller.write(path, kind, data)
    return Registry.write.write(path, kind, data)
end

----------------------------------------------------------------
-- STRICT variants (opt-in)
----------------------------------------------------------------

--- Read a file (STRICT).
--- Throws on failure.
---@param path string
---@return table result
function Controller.read_strict(path)
    local result, err = Registry.read.read(path)
    if not result then
        error(err, 2)
    end
    return result
end

--- Read table input (STRICT).
---@param path string
---@return IOTableResult
function Controller.read_table_strict(path)
    local result, err = Registry.read.read(path)
    if not result then
        error(err, 2)
    end

    if result.kind ~= "table" then
        error("expected table input, got " .. tostring(result.kind), 2)
    end

    return result
end

--- Read and normalize records (STRICT).
---@param path string
---@return table records
function Controller.read_records_strict(path)
    local records, err = Controller.read_records(path)
    if not records then
        error(err, 2)
    end
    return records
end

--- Write structured data to disk (STRICT).
---@param path string
---@param kind string
---@param data any
---@return table meta
function Controller.write_strict(path, kind, data)
    local meta, err = Registry.write.write(path, kind, data)
    if not meta then
        error(err, 2)
    end
    return meta
end

----------------------------------------------------------------
-- Stream lines to a sink (RELAXED but validated)
----------------------------------------------------------------

--- Stream iterable lines to a sink.
---@param iter fun(): any|nil
---@param sink table  -- must support :write()
---@return true
function Controller.stream(iter, sink)
    assert(type(iter) == "function", "iter must be function")
    assert(type(sink) == "table" and sink.write, "sink must support :write()")

    while true do
        local v = iter()
        if v == nil then
            break
        end
        sink:write(v)
    end
    return true
end

return Controller
