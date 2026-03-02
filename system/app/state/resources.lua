-- system/app/data/resources.lua

local Runtime = require("core.domain.runtime").controller

---@class AppDataResources
---@field private __app Surface
---@field private __state table
local Resources = {}
Resources.__index = Resources

---@param app Surface
---@param state table
---@return AppDataResources
function Resources.new(app, state)
    state.resources.system = state.resources.system or {}
    state.resources.user   = state.resources.user   or {}

    ---@type AppDataResources
    local instance = setmetatable({
        __app   = app,
        __state = state
    }, Resources)

    return instance
end

------------------------------------------------------------
-- Accessors
------------------------------------------------------------

function Resources:user()
    return self.__state.resources.user
end

function Resources:system()
    return self.__state.resources.system
end

------------------------------------------------------------
-- Runtime Loader Entry
------------------------------------------------------------

---@param entry table
---@return RuntimeResult
function Resources:load_entry(entry)

    assert(entry and entry.load_spec,
        "[resources] invalid resource entry")

    local spec = entry.load_spec

    if spec.type == "single" then
        return Runtime.load_strict(spec.path)

    elseif spec.type == "associate" then
        local order_rt = Runtime.load_strict(spec.order_path)
        local board_rt = Runtime.load_strict(spec.boards_path)
        return Runtime.associate(order_rt, board_rt)

    else
        error("[resources] unknown load_spec type: " .. tostring(spec.type), 2)
    end
end

------------------------------------------------------------
-- System Store Scan (DESCRIPTORS ONLY)
------------------------------------------------------------

---@return table
function Resources:pull_system()

    local fs    = self.__app:fs()
    local store = fs:store()

    local system_resources = {}

    local function ensure_role(role)
        if not system_resources[role] then
            system_resources[role] = {}
        end
        return system_resources[role]
    end

    ------------------------------------------------------------
    -- Vendor
    ------------------------------------------------------------
    do
        local root = store:vendor()
        local inspection = root:inspect()

        if inspection.exists() and inspection.is_directory() then
            for _, path in ipairs(root:files()) do
                local id = path:match("([^/]+)%.csv$")
                if id then
                    table.insert(ensure_role("vendor"), {
                        id   = id,
                        kind = "vendor",
                        load_spec = {
                            type = "single",
                            path = path
                        }
                    })
                end
            end
        end
    end

    ------------------------------------------------------------
    -- Ledger
    ------------------------------------------------------------
    do
        local root = store:ledger()
        local inspection = root:inspect()

        if inspection.exists() and inspection.is_directory() then
            for _, path in ipairs(root:files()) do
                local id = path:match("([^/]+)$")
                table.insert(ensure_role("ledger"), {
                    id   = id,
                    kind = "ledger",
                    load_spec = {
                        type = "single",
                        path = path
                    }
                })
            end
        end
    end

    ------------------------------------------------------------
    -- Client
    ------------------------------------------------------------
    do
        local root = store:client()
        local inspection = root:inspect()

        if inspection.exists() and inspection.is_directory() then
            for _, path in ipairs(root:files()) do
                local id = path:match("([^/]+)$")
                table.insert(ensure_role("client"), {
                    id   = id,
                    kind = "client",
                    load_spec = {
                        type = "single",
                        path = path
                    }
                })
            end
        end
    end

    self.__state.resources.system = system_resources

    return { status = "system resources registered" }
end

------------------------------------------------------------
-- User Inputs → Canonical Resource Descriptors
------------------------------------------------------------

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

        if role == "job" then
            local entry

            if descriptor.path then
                entry = {
                    kind = "job",
                    load_spec = {
                        type = "single",
                        path = descriptor.path
                    }
                }
            else
                entry = {
                    kind = "job",
                    load_spec = {
                        type        = "associate",
                        order_path  = descriptor.order_path,
                        boards_path = descriptor.boards_path
                    }
                }
            end

            table.insert(ensure_role("job"), entry)

        elseif role == "vendor" then
            table.insert(ensure_role("vendor"), {
                id   = descriptor.name,
                kind = "vendor",
                load_spec = {
                    type = "single",
                    path = descriptor.path
                }
            })

        elseif role == "client" then
            table.insert(ensure_role("client"), {
                kind = "client",
                load_spec = {
                    type = "single",
                    path = descriptor.path
                }
            })

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

------------------------------------------------------------
-- Canonical Get API
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param identifier string|nil
---@return table|nil
function Resources:get(scope, role, identifier)

    assert(scope == "system" or scope == "user",
        "[resources] invalid scope")

    assert(type(role) == "string",
        "[resources] role required")

    local bucket = self.__state.resources[scope]
    if not bucket then return nil end

    local list = bucket[role]
    if not list then return nil end

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

return Resources
