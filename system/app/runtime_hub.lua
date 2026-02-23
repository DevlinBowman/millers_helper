local RuntimeController = require("core.domain.runtime.controller")

---@class RuntimeHub
---@field _specs table
---@field _cache table<string, any>
local RuntimeHub = {}
RuntimeHub.__index = RuntimeHub

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------

local function split_path(s)
    local parts = {}
    if type(s) ~= "string" or s == "" then
        return parts
    end
    for part in string.gmatch(s, "([^%.]+)") do
        parts[#parts + 1] = part
    end
    return parts
end

local function get_by_path(root, path)
    local parts = split_path(path)
    local current = root
    for i = 1, #parts do
        if type(current) ~= "table" then
            return nil
        end
        current = current[parts[i]]
    end
    return current
end

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param initial_specs? table
---@return RuntimeHub
function RuntimeHub.new(initial_specs)
    local self = setmetatable({}, RuntimeHub)
    self._specs = initial_specs or {}
    self._cache = {}
    return self
end

----------------------------------------------------------------
-- Spec Access
----------------------------------------------------------------

---@param path string
function RuntimeHub:invalidate(path)
    if type(path) ~= "string" or path == "" then
        return
    end
    self._cache[path] = nil
end

---@param path string
---@return table|nil
function RuntimeHub:spec(path)
    local v = get_by_path(self._specs, path)
    if type(v) ~= "table" then
        return nil
    end
    if v.inputs == nil then
        return nil
    end
    return v
end

---@param path string
---@return boolean
function RuntimeHub:is_configured(path)
    return self:spec(path) ~= nil
end

---@param path string
---@return boolean
function RuntimeHub:is_loaded(path)
    return self._cache[path] ~= nil
end

----------------------------------------------------------------
-- Error Normalization
----------------------------------------------------------------

function RuntimeHub:_format_load_error(resource_name, err)
    if type(err) ~= "table" then
        return {
            ok       = false,
            kind     = "runtime_load_failure",
            resource = resource_name,
            message  = tostring(err)
        }
    end

    local decode_err =
        err.error
        and err.error.error

    if decode_err
        and decode_err.kind == "parser_validation_error"
        and decode_err.errors
    then
        return {
            ok       = false,
            kind     = "user_input_error",
            resource = resource_name,
            path     = err.path,
            message  = "Some input data could not be parsed.",
            details  = decode_err.errors
        }
    end

    return {
        ok       = false,
        kind     = "runtime_load_failure",
        resource = resource_name,
        message  = err.message or tostring(err)
    }
end

----------------------------------------------------------------
-- Core Loading
----------------------------------------------------------------

---@param path string
---@return any|nil runtime
---@return table|string|nil err
function RuntimeHub:load(path)
    local spec = self:spec(path)
    if not spec then
        return nil, "missing spec: " .. tostring(path)
    end

    local inputs = spec.inputs
    local opts   = spec.opts or {}

    if type(inputs) ~= "table" then
        return nil, "resource inputs must be table"
    end

    ------------------------------------------------------------
    -- Single Input
    ------------------------------------------------------------

    if #inputs == 1 then
        local runtime, err =
            RuntimeController.load(inputs[1], opts)

        if not runtime then
            return nil, self:_format_load_error(path, err)
        end

        self._cache[path] = runtime
        return runtime
    end

    ------------------------------------------------------------
    -- Multi Input Merge
    ------------------------------------------------------------

    local merged_batches = {}

    for _, input_value in ipairs(inputs) do
        local runtime, err =
            RuntimeController.load(input_value, opts)

        if not runtime then
            return nil, self:_format_load_error(path, err)
        end

        for _, batch in ipairs(runtime:batches() or {}) do
            merged_batches[#merged_batches + 1] = batch
        end
    end

    local merged_runtime = {
        batches = function()
            return merged_batches
        end
    }

    self._cache[path] = merged_runtime
    return merged_runtime
end

----------------------------------------------------------------
-- Accessors
----------------------------------------------------------------

---@param path string
---@return any|nil runtime
---@return table|string|nil err
function RuntimeHub:get(path)
    if self._cache[path] then
        return self._cache[path]
    end
    return self:load(path)
end

---@param path string
---@return any|nil runtime
---@return table|string|nil err
function RuntimeHub:require(path)
    return self:get(path)
end

return RuntimeHub
