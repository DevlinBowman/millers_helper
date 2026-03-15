-- system/app/state/resources.lua

local Schema = require("system.app.state.resource_schema")

---@class AppDataResources
---@field private __app Surface
---@field private __resources table
---@field private __read_inputs fun():table
local Resources = {}
Resources.__index = Resources

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@param resources_state table
---@param read_inputs fun():table
---@return AppDataResources
function Resources.new(app, resources_state, read_inputs)

    assert(type(app) == "table", "[resources] app required")
    assert(type(resources_state) == "table", "[resources] state required")
    assert(type(read_inputs) == "function", "[resources] read_inputs required")

    resources_state.system = resources_state.system or {}
    resources_state.user   = resources_state.user   or {}

    return setmetatable({
        __app         = app,
        __resources   = resources_state,
        __read_inputs = read_inputs,
    }, Resources)
end

------------------------------------------------------------
-- Accessors
------------------------------------------------------------

function Resources:user()
    return self.__resources.user
end

function Resources:system()
    return self.__resources.system
end

------------------------------------------------------------
-- Descriptor Registration
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param descriptor table
---@return table
function Resources:add(scope, role, descriptor)

    Schema.assert_scope(scope)
    Schema.assert_role(role)

    assert(type(descriptor) == "table",
        "[resources] descriptor table required")

    local bucket = self.__resources[scope]

    bucket[role] = bucket[role] or {}
    table.insert(bucket[role], descriptor)

    return descriptor
end

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

---@private
---@param role string
---@param path string
---@param id string|nil
---@return table
local function build_single_descriptor(role, path, id)

    return {
        id   = id,
        kind = role,
        load_spec = {
            type = "single",
            path = path
        }
    }
end

---@private
---@param role string
---@param root AppFSResult
---@param id_pattern string|nil
---@return table
local function scan_directory(role, root, id_pattern)

    local inspection = root:inspect()

    if not inspection.exists() or not inspection.is_directory() then
        return {}
    end

    local out = {}

    for _, path in ipairs(root:files()) do

        local id

        if id_pattern then
            id = path:match(id_pattern)
        else
            id = path:match("([^/]+)$")
        end

        table.insert(out, build_single_descriptor(role, path, id))
    end

    return out
end

---@private
---@param role string
---@param input_descriptor table
---@return table
function Resources:_build_input_descriptor(role, input_descriptor)

    assert(type(role) == "string" and role ~= "",
        "[resources] role required")

    assert(type(input_descriptor) == "table",
        "[resources] input_descriptor required")

    if role == "job" then

        if input_descriptor.path then
            return {
                kind = "job",
                load_spec = {
                    type = "single",
                    path = input_descriptor.path
                }
            }
        end

        return {
            kind = "job",
            load_spec = {
                type        = "associate",
                order_path  = input_descriptor.order_path,
                boards_path = input_descriptor.boards_path
            }
        }
    end

    if role == "vendor" then
        return {
            id   = input_descriptor.name,
            kind = "vendor",
            load_spec = {
                type = "single",
                path = input_descriptor.path
            }
        }
    end

    if role == "client" then
        return {
            kind = "client",
            load_spec = {
                type = "single",
                path = input_descriptor.path
            }
        }
    end

    if role == "ledger" then
        return {
            kind = "ledger",
            load_spec = {
                type = "single",
                path = input_descriptor.path
            }
        }
    end

    error("[resources] unsupported input role: " .. tostring(role), 2)
end

------------------------------------------------------------
-- System Descriptor Registration
------------------------------------------------------------

---@return table
function Resources:pull_system()

    local store =
        self.__app:fs():store()

    local system =
        self.__resources.system

    system.vendor =
        scan_directory(
            "vendor",
            store:vendor(),
            "([^/]+)%.csv$"
        )

    system.ledger =
        scan_directory(
            "ledger",
            store:ledger()
        )

    system.client =
        scan_directory(
            "client",
            store:client()
        )

    return {
        status = "system resources registered"
    }
end

------------------------------------------------------------
-- User Inputs → Resource Descriptors
------------------------------------------------------------

---@param role string
---@param input_descriptor table
---@return table
function Resources:register_input(role, input_descriptor)

    local descriptor =
        self:_build_input_descriptor(role, input_descriptor)

    return self:add("user", role, descriptor)
end

---@return table
function Resources:pull_user_from_inputs()

    local inputs =
        self.__read_inputs() or {}

    self.__resources.user = {}

    for role, input_descriptor in pairs(inputs) do

        assert(type(input_descriptor) == "table",
            "[resources] invalid input descriptor for role: "
            .. tostring(role))

        self:register_input(role, input_descriptor)
    end

    return {
        status = "user resources registered"
    }
end

------------------------------------------------------------
-- Descriptor Access
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param identifier string|nil
---@return table|nil
function Resources:get(scope, role, identifier)

    Schema.assert_scope(scope)

    assert(type(role) == "string" and role ~= "",
        "[resources] role required")

    local bucket =
        self.__resources[scope]

    if type(bucket) ~= "table" then
        return nil
    end

    local list =
        bucket[role]

    if type(list) ~= "table" then
        return nil
    end

    if not identifier then
        return list
    end

    for _, entry in ipairs(list) do
        if entry.id == identifier then
            return entry
        end
    end

    return nil
end

------------------------------------------------------------
-- Strict Single Descriptor
------------------------------------------------------------

---@param scope ResourceScope
---@param role ResourceRole
---@param field ResourceField|nil
---@return any
function Resources:get_one(scope, role, field)

    Schema.assert_scope(scope)
    Schema.assert_role(role)

    local list =
        self:get(scope, role)

    assert(type(list) == "table",
        "[resources] no descriptors for "
        .. scope .. "." .. role)

    if #list ~= 1 then
        error(
            "[resources] expected exactly 1 descriptor for "
            .. scope .. "." .. role
            .. " but found "
            .. tostring(#list),
            2
        )
    end

    local descriptor = list[1]

    if not field then
        return descriptor
    end

    local location =
        Schema.assert_field(role, field)

    if location == "direct" then
        return descriptor[field]
    end

    return descriptor.load_spec
        and descriptor.load_spec[field]
end

return Resources
