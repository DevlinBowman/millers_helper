-- core/engine/dto.lua
--
-- DTO: runtime wrapper over Core domain definitions.
-- Enforces:
--   • alias -> canonical key resolution
--   • mutability policy
--   • basic type checks
--   • optional strict reference validation (closed-world symbols)

local Resolver = require("core.engine.runtime.resolver")
local Validate = require("core.engine.runtime.validation")

---@class DTO
---@field private _domain string
---@field private _data table<string, any>
local DTO = {}
DTO.__index = DTO

------------------------------------------------
-- constructor
------------------------------------------------

---@param domain string
---@param data table<string, any>|nil
---@return DTO
function DTO.new(domain, data)
    local self   = setmetatable({}, DTO)

    self._domain = domain
    self._data   = data or {}

    return self
end

------------------------------------------------
-- accessors
------------------------------------------------

---@return string
function DTO:domain()
    return self._domain
end

---@return table
function DTO:data()
    return self._data
end

------------------------------------------------
-- getters
------------------------------------------------

---@param key string
---@return any
function DTO:get(key)
    local field = Resolver.field(self._domain, key)

    if field then
        return self._data[field.name]
    end

    return self._data[key]
end

------------------------------------------------
-- type checking
------------------------------------------------

local function type_ok(expected, v)
    if v == nil then
        return true
    end

    if expected == "symbol" then
        return type(v) == "string"
    end

    if expected == "number" then
        return type(v) == "number"
    end

    if expected == "string" then
        return type(v) == "string"
    end

    if expected == "boolean" then
        return type(v) == "boolean"
    end

    if expected == "table" then
        return type(v) == "table"
    end

    return false
end

------------------------------------------------
-- setters
------------------------------------------------

---@param key string
---@param value any
---@param opts? { strict?: boolean }
---@return boolean ok, string|nil err
function DTO:set(key, value, opts)
    opts = opts or {}

    local field = Resolver.field(self._domain, key)

    -- Unknown field: reject by default (schema is ultimate authority)
    if not field then
        if opts.strict == false then
            self._data[key] = value
            return true, nil
        end
        return false, "unknown_field:" .. tostring(key)
    end

    if field.mutable == false then
        return false, "field_not_mutable:" .. field.name
    end

    if not type_ok(field.type, value) then
        return false, "field_type_mismatch:" .. field.name
    end

    -- strict closed-world symbol validation only when reference exists
    if opts.strict and value ~= nil and field.reference then
        local ref_domain = Resolver.reference(field.reference, self._domain)
        if not ref_domain then
            return false, "reference_domain_not_found:" .. field.reference
        end

        local values = require("core.engine.runtime.state").values[ref_domain]
        if not values or not values.lookup[value] then
            return false, "field_value_not_allowed:" .. field.name
        end

        -- reject alias usage
        local enum = values.lookup[value]
        if enum.name ~= value then
            return false, "alias_not_allowed:" .. field.name
        end
    end

    self._data[field.name] = value
    return true, nil
end

------------------------------------------------
-- patch application
------------------------------------------------

---@param patch table<string, any>
---@param opts? { strict?: boolean }
---@return boolean ok, table|nil errors
function DTO:apply(patch, opts)
    opts = opts or {}

    if type(patch) ~= "table" then
        return false, { "patch_must_be_table" }
    end

    local errors = {}

    for k, v in pairs(patch) do
        local ok, err = self:set(k, v, opts)

        if not ok then
            errors[#errors + 1] = err
        end
    end

    if #errors > 0 then
        return false, errors
    end

    return true, nil
end

------------------------------------------------
-- validation helpers
------------------------------------------------

---@return boolean, table
function DTO:exists()
    return Validate.exists(self._domain, self._data)
end

---@return boolean, table
function DTO:validate()
    return Validate.validate(self._domain, self._data)
end

---@return boolean, table|nil
function DTO:check()
    return Validate.check(self._domain, self._data)
end

------------------------------------------------
-- export
------------------------------------------------

-- ---@return table<string, any>
-- function DTO:export()
--     return self._data
-- end
--
function DTO:export()

    local out = {}

    for k, v in pairs(self._data) do
        out[k] = v
    end

    return out
end

return DTO
