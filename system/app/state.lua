-- system/app/state.lua
--
-- State
-- =====
-- Persisted:
--   - context   (session key/value)
--   - resources (runtime spec tree; namespaced)
--
-- Ephemeral:
--   - results   (service outputs; never persisted)

---@class State
---@field context table<string, any>
---@field resources table
---@field results table<string, any>
local State = {}
State.__index = State

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

---@param value any
---@return table
local function ensure_table(value)
    if type(value) == "table" then
        return value
    end
    return {}
end

---@param s string
---@return string[]
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

---@param root table
---@param path string
---@param create boolean
---@return table|nil parent
---@return string|nil key
local function walk_parent(root, path, create)
    local parts = split_path(path)
    if #parts == 0 then
        return nil, nil
    end

    local current = root
    for i = 1, #parts - 1 do
        local k = parts[i]
        if type(current[k]) ~= "table" then
            if not create then
                return nil, nil
            end
            current[k] = {}
        end
        current = current[k]
    end

    return current, parts[#parts]
end

---@param root table
---@param path string
---@return any
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

---@param initial? table
---@return State
function State.new(initial)
    initial = ensure_table(initial)

    local self = setmetatable({}, State)

    self.context   = ensure_table(initial.context)
    self.resources = ensure_table(initial.resources)
    self.results   = ensure_table(initial.results)

    -- Ensure namespace roots exist deterministically
    self.resources.user   = ensure_table(self.resources.user)
    self.resources.system = ensure_table(self.resources.system)

    return self
end

----------------------------------------------------------------
-- Resource Spec Tree
----------------------------------------------------------------
-- Resources are stored as a tree under:
--   resources.user
--   resources.system
--
-- Leaf nodes are runtime specs:
--   { inputs = {...}, opts = {...} }

---@param path string
---@param spec table
---@return boolean|string
function State:set_resource(path, spec)
    if type(path) ~= "string" or path == "" then
        return false, "invalid resource path"
    end
    if type(spec) ~= "table" then
        return false, "resource spec must be table"
    end
    if spec.inputs == nil then
        return false, "resource spec missing inputs"
    end

    spec.opts = ensure_table(spec.opts)

    local parent, key = walk_parent(self.resources, path, true)
    if not parent or not key then
        return false, "invalid resource path"
    end

    parent[key] = spec
    return true
end

---@param path string
---@return table|nil
function State:get_resource(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    local v = get_by_path(self.resources, path)
    if type(v) ~= "table" then
        return nil
    end
    -- leaf spec must have inputs; otherwise it's a namespace node
    if v.inputs == nil then
        return nil
    end
    return v
end

---@param path string
---@return boolean|string
function State:clear_resource(path)
    if type(path) ~= "string" or path == "" then
        return false, "invalid resource path"
    end

    local parent, key = walk_parent(self.resources, path, false)
    if not parent or not key then
        return false, "resource path not found"
    end

    parent[key] = nil
    return true
end

---@return table
function State:resources_table()
    return self.resources
end

----------------------------------------------------------------
-- Context (Persisted)
----------------------------------------------------------------

---@param key string
---@param value any
---@return boolean|string
function State:set_context(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "invalid context key"
    end
    self.context[key] = value
    return true
end

---@param key string
---@return any
function State:get_context(key)
    if type(key) ~= "string" then
        return nil
    end
    return self.context[key]
end

---@return table<string, any>
function State:context_table()
    return self.context
end

----------------------------------------------------------------
-- Results (Ephemeral)
----------------------------------------------------------------

---@param key string
---@param value any
---@return boolean|string
function State:set_result(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "invalid result key"
    end
    self.results[key] = value
    return true
end

---@param key string
---@return any
function State:get_result(key)
    if type(key) ~= "string" then
        return nil
    end
    return self.results[key]
end

---@param key string
---@return boolean|string
function State:clear_result(key)
    if type(key) ~= "string" then
        return false, "invalid result key"
    end
    self.results[key] = nil
    return true
end

----------------------------------------------------------------
-- Reset / Clear Helpers
----------------------------------------------------------------

function State:clear_resources()
    -- Do NOT replace the table reference.
    -- Mutate existing namespace roots to preserve hub._specs reference.

    if type(self.resources) ~= "table" then
        self.resources = {}
    end

    self.resources.user   = {}
    self.resources.system = {}

    return true
end

function State:clear_results()
    self.results = {}
    return true
end

function State:clear_context()
    self.context = {}
    return true
end

function State:reset()
    -- Reset persisted context
    self.context = {}

    -- Preserve table reference integrity
    if type(self.resources) ~= "table" then
        self.resources = {}
    end

    self.resources.user   = {}
    self.resources.system = {}

    -- Reset ephemeral results
    self.results = {}

    return true
end

----------------------------------------------------------------
-- Persistable Snapshot
----------------------------------------------------------------

---@return { version: number, context: table, resources: table }
function State:to_persistable()
    return {
        version   = 1,
        context   = self.context,
        resources = self.resources,
    }
end

return State
