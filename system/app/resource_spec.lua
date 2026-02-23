-- system/app/resource_spec.lua
--
-- Canonical builder for runtime resource specs.

local ResourceSpec = {}

---@param path string
---@param category? string
---@param extra_opts? table
---@return table
function ResourceSpec.simple(path, category, extra_opts)
    assert(type(path) == "string" and path ~= "", "path required")

    local opts = extra_opts or {}
    if category then
        opts.category = category
    end

    return {
        inputs = { path },
        opts   = opts
    }
end

---@param paths string[]
---@param category? string
---@param extra_opts? table
---@return table
function ResourceSpec.multi(paths, category, extra_opts)
    assert(type(paths) == "table", "paths must be table")

    local opts = extra_opts or {}
    if category then
        opts.category = category
    end

    return {
        inputs = paths,
        opts   = opts
    }
end

return ResourceSpec
