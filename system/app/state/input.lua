---@class AppDataInput
---@field private __state table
local Input = {}
Input.__index = Input

----------------------------------------------------------------
-- Role Schema
----------------------------------------------------------------

---@class JobInput
---@field path string|nil
---@field order_path string|nil
---@field boards_path string|nil

---@class VendorInput
---@field path string
---@field name string

local ROLE_SCHEMA = {

    job = function(payload)
        assert(type(payload) == "table", "[data.input] job payload must be table")

        -- single-file job
        if payload.path then
            assert(type(payload.path) == "string", "[data.input] job.path must be string")
            return {
                path = payload.path
            }
        end

        -- split job
        if payload.order_path and payload.boards_path then
            assert(type(payload.order_path) == "string", "[data.input] order_path must be string")
            assert(type(payload.boards_path) == "string", "[data.input] boards_path must be string")
            return {
                order_path = payload.order_path,
                boards_path = payload.boards_path
            }
        end

        error("[data.input] invalid job payload shape", 2)
    end,

    vendor = function(payload)
        assert(type(payload) == "table", "[data.input] vendor payload must be table")
        assert(type(payload.path) == "string", "[data.input] vendor.path required")
        assert(type(payload.name) == "string", "[data.input] vendor.name required")

        return {
            path = payload.path,
            name = payload.name,
        }
    end,

    client = function(payload)
        assert(type(payload) == "table", "[data.input] client payload must be table")
        assert(type(payload.path) == "string", "[data.input] client.path required")

        return {
            path = payload.path
        }
    end,

    ledger = function(payload)
        assert(type(payload) == "table", "[data.input] ledger payload must be table")
        assert(type(payload.path) == "string", "[data.input] ledger.path required")

        return {
            path = payload.path
        }
    end,
}

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@return AppDataInput
function Input.new(state)
    ---@type AppDataInput
    local instance = setmetatable({ __state = state }, Input)
    return instance
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---Set a resource input by role.
---Overwrites existing role.
---@param role string
---@param payload table
---@return table descriptor
function Input:set(role, payload)
    local validator = ROLE_SCHEMA[role]
    assert(validator, "[data.input] invalid role: " .. tostring(role))

    local descriptor = validator(payload)

    self.__state.inputs.by_role[role] = descriptor

    -- AUTO PROMOTE
    if self.__state.resources and self.__state.resources.user then
        local function ensure_role(role_name)
            local bucket = self.__state.resources.user
            if not bucket[role_name] then
                bucket[role_name] = {}
            end
            return bucket[role_name]
        end

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
                kind      = "vendor",
                id        = descriptor.name,
                load_spec = {
                    type = "single",
                    path = descriptor.path
                }
            })
        elseif role == "client" then
            table.insert(ensure_role("client"), {
                kind = "client",
                path = descriptor.path
            })
        elseif role == "ledger" then
            table.insert(ensure_role("ledger"), {
                kind = "ledger",
                path = descriptor.path
            })
        end
    end
    return descriptor
end

---Get descriptor by role.
---@param role string
---@return table|nil
function Input:get(role)
    return self.__state.inputs.by_role[role]
end

---Return full raw input map.
---@return table
function Input:all()
    return self.__state.inputs.by_role
end

---Clear one role or all.
---@param role string|nil
function Input:clear(role)
    if role then
        self.__state.inputs.by_role[role] = nil
    else
        self.__state.inputs.by_role = {}
    end
end

return Input
