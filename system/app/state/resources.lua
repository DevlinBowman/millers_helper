-- system/app/data/resources.lua

local Runtime = require("core.domain.runtime").controller
local Schema = require("system.app.state.resource_schema")

---@class AppDataResources
---@field private __app Surface
---@field private __state table
local Resources = {}
Resources.__index = Resources

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param app Surface
---@param state table
---@return AppDataResources
function Resources.new(app, state)
    assert(type(app) == "table", "[resources] app required")
    assert(type(state) == "table", "[resources] state required")

    state.resources = state.resources or {}
    state.resources.system = state.resources.system or {}
    state.resources.user   = state.resources.user   or {}

    return setmetatable({
        __app   = app,
        __state = state
    }, Resources)
end

----------------------------------------------------------------
-- Accessors
----------------------------------------------------------------

function Resources:user()
    return self.__state.resources.user
end

function Resources:system()
    return self.__state.resources.system
end

----------------------------------------------------------------
-- Runtime Loader Entry
----------------------------------------------------------------

---@param entry table
---@return RuntimeResult
function Resources:load_entry(entry)

    assert(type(entry) == "table", "[resources] entry required")
    assert(type(entry.load_spec) == "table", "[resources] load_spec missing")

    local spec = entry.load_spec

    if spec.type == "single" then
        assert(type(spec.path) == "string", "[resources] single spec.path required")
        return Runtime.load_strict(spec.path)

    elseif spec.type == "associate" then
        assert(type(spec.order_path)  == "string", "[resources] associate order_path required")
        assert(type(spec.boards_path) == "string", "[resources] associate boards_path required")

        local order_rt = Runtime.load_strict(spec.order_path)
        local board_rt = Runtime.load_strict(spec.boards_path)

        return Runtime.associate(order_rt, board_rt)

    else
        error("[resources] unknown load_spec type: " .. tostring(spec.type), 2)
    end
end

----------------------------------------------------------------
-- Internal Helpers
----------------------------------------------------------------

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

        if id then
            table.insert(out, build_single_descriptor(role, path, id))
        end
    end

    return out
end

----------------------------------------------------------------
-- System Store Scan (DESCRIPTORS ONLY)
----------------------------------------------------------------

---@return table
function Resources:pull_system()

    local store = self.__app:fs():store()

    local system_resources = {
        vendor = scan_directory("vendor", store:vendor(), "([^/]+)%.csv$"),
        ledger = scan_directory("ledger", store:ledger()),
        client = scan_directory("client", store:client()),
    }

    self.__state.resources.system = system_resources

    return { status = "system resources registered" }
end

----------------------------------------------------------------
-- User Inputs → Canonical Resource Descriptors
----------------------------------------------------------------

---@return table
function Resources:pull_user_from_inputs()

    local inputs = self.__state.inputs.by_role or {}
    local user_resources = {}

    local function ensure_role(role)
        if not user_resources[role] then
            user_resources[role] = {}
        end
        return user_resources[role]
    end

    for role, descriptor in pairs(inputs) do

        assert(type(descriptor) == "table",
            "[resources] invalid input descriptor for role: " .. tostring(role))

        --------------------------------------------------------
        -- Job
        --------------------------------------------------------
        if role == "job" then

            if descriptor.path then
                table.insert(ensure_role("job"), {
                    kind = "job",
                    load_spec = {
                        type = "single",
                        path = descriptor.path
                    }
                })
            else
                table.insert(ensure_role("job"), {
                    kind = "job",
                    load_spec = {
                        type        = "associate",
                        order_path  = descriptor.order_path,
                        boards_path = descriptor.boards_path
                    }
                })
            end

        --------------------------------------------------------
        -- Vendor
        --------------------------------------------------------
        elseif role == "vendor" then

            table.insert(ensure_role("vendor"), {
                id   = descriptor.name,
                kind = "vendor",
                load_spec = {
                    type = "single",
                    path = descriptor.path
                }
            })

        --------------------------------------------------------
        -- Client
        --------------------------------------------------------
        elseif role == "client" then

            table.insert(ensure_role("client"), {
                kind = "client",
                load_spec = {
                    type = "single",
                    path = descriptor.path
                }
            })

        --------------------------------------------------------
        -- Ledger
        --------------------------------------------------------
        elseif role == "ledger" then

            table.insert(ensure_role("ledger"), {
                kind = "ledger",
                load_spec = {
                    type = "single",
                    path = descriptor.path
                }
            })
        end
    end

    self.__state.resources.user = user_resources

    return { status = "user resources registered" }
end

----------------------------------------------------------------
-- Canonical Get API
----------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param identifier string|nil
---@return table|nil
function Resources:get(scope, role, identifier)

    assert(scope == "system" or scope == "user",
        "[resources] invalid scope")

    assert(type(role) == "string" and role ~= "",
        "[resources] role required")

    local bucket = self.__state.resources[scope]
    if type(bucket) ~= "table" then
        return nil
    end

    local list = bucket[role]
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

---Return single descriptor or a nested field of it.
---Errors if none or more than one descriptor exists.
---@param scope ResourceScope
---@param role ResourceRole
---@param field ResourceField|nil
---@return any
function Resources:get_one(scope, role, field)

    Schema.assert_scope(scope)
    Schema.assert_role(role)

    local list = self:get(scope, role)

    assert(type(list) == "table",
        "[resources] no descriptors for " .. scope .. "." .. role)

    if #list ~= 1 then
        error(
            "[resources] expected exactly 1 descriptor for "
            .. scope .. "." .. role
            .. " but found " .. tostring(#list),
            2
        )
    end

    local descriptor = list[1]

    if not field then
        return descriptor
    end

    assert(type(field) == "string" and field ~= "",
        "[resources] field must be string")

    local location = Schema.assert_field(role, field)

    if location == "direct" then
        return descriptor[field]
    elseif location == "load_spec" then
        return descriptor.load_spec and descriptor.load_spec[field]
    end
end

return Resources
