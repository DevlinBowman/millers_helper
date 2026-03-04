-- system/app/state/resource_schema.lua

---@class ResourceRoleSchema
---@field fields table<string, true>
---@field load_spec_fields table<string, true>|nil

----------------------------------------------------------------
-- LSP Literal Types
----------------------------------------------------------------

---@alias ResourceScope "system"|"user"
---@alias ResourceRole  "job"|"vendor"|"client"|"ledger"

---@alias ResourceField
---| "id"
---| "kind"
---| "path"
---| "order_path"
---| "boards_path"

----------------------------------------------------------------

local Schema = {}

Schema.SCOPES = {
    system = true,
    user   = true,
}

Schema.ROLES = {

    job = {
        fields = {
            kind = true,
        },
        load_spec_fields = {
            path        = true,
            order_path  = true,
            boards_path = true,
        }
    },

    vendor = {
        fields = {
            id   = true,
            kind = true,
        },
        load_spec_fields = {
            path = true,
        }
    },

    client = {
        fields = {
            kind = true,
        },
        load_spec_fields = {
            path = true,
        }
    },

    ledger = {
        fields = {
            kind = true,
        },
        load_spec_fields = {
            path = true,
        }
    }
}

----------------------------------------------------------------
-- Validators
----------------------------------------------------------------

---@param scope ResourceScope
function Schema.assert_scope(scope)
    assert(Schema.SCOPES[scope],
        "[resource.schema] invalid scope: " .. tostring(scope))
end

---@param role ResourceRole
function Schema.assert_role(role)
    assert(Schema.ROLES[role],
        "[resource.schema] invalid role: " .. tostring(role))
end

---@param role ResourceRole
---@param field ResourceField
---@return "direct"|"load_spec"
function Schema.assert_field(role, field)
    local role_schema = Schema.ROLES[role]
    assert(role_schema,
        "[resource.schema] invalid role: " .. tostring(role))

    if role_schema.fields[field] then
        return "direct"
    end

    if role_schema.load_spec_fields
        and role_schema.load_spec_fields[field]
    then
        return "load_spec"
    end

    error(
        "[resource.schema] invalid field '" .. field ..
        "' for role '" .. role .. "'",
        2
    )
end

return Schema
