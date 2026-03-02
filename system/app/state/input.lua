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

---@param state table
---@return AppDataInput
function Input.new(state)
    assert(type(state) == "table", "[data.input] state required")

    state.inputs = state.inputs or {}
    state.inputs.by_role = state.inputs.by_role or {}

    ---@type AppDataInput
    local instance = setmetatable({
        __state = state
    }, Input)

    return instance
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---Set input descriptor for a role.
---Overwrites any existing descriptor for that role.
---@param role string
---@param payload table
---@return table descriptor
function Input:set(role, payload)
    assert(type(role) == "string" and role ~= "",
        "[data.input] role required")

    local validator = ROLE_SCHEMA[role]
    assert(validator,
        "[data.input] invalid role: " .. tostring(role))

    local descriptor = validator(payload)

    self.__state.inputs.by_role[role] = descriptor

    return descriptor
end

---Get descriptor for a role.
---@param role string
---@return table|nil
function Input:get(role)
    assert(type(role) == "string" and role ~= "",
        "[data.input] role required")

    return self.__state.inputs.by_role[role]
end

---Return entire input map (by_role).
---@return table
function Input:all()
    return self.__state.inputs.by_role
end

---Clear one role or all roles.
---@param role string|nil
function Input:clear(role)
    if role then
        assert(type(role) == "string",
            "[data.input] role must be string")
        self.__state.inputs.by_role[role] = nil
    else
        self.__state.inputs.by_role = {}
    end
end

return Input
