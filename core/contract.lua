-- core/contract.lua
--
-- Structural contract enforcement (presence-only).
-- No domain logic.
--
-- Supports:
--   - required key:      key = true
--   - optional key:      ["key?"] = true
--   - nested table:      key = { ... }
--   - optional nested:   ["key?"] = { ... }
--   - legacy strings are treated as presence-only:
--       "table", "array", "string", "table?", etc.
--     (no type checks; "?" makes it optional)
--   - shape == true means "no enforcement"

local Contract = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

---@param k any
---@return string key
---@return boolean optional
local function parse_key(k)
    local key = tostring(k)
    if key:sub(-1) == "?" then
        return key:sub(1, -2), true
    end
    return key, false
end

---@param spec any
---@return boolean optional
local function spec_is_optional(spec)
    if type(spec) ~= "string" then
        return false
    end
    return spec:sub(-1) == "?"
end

----------------------------------------------------------------
-- Recursive validator (presence-only)
----------------------------------------------------------------

---@param value any
---@param shape any
---@param path? string
---@return boolean ok
---@return string? err
local function validate_shape(value, shape, path)
    path = path or "root"

    -- no enforcement / allow-any
    if shape == true then
        return true
    end

    -- nil/false shape means "ignore"
    if shape == nil or shape == false then
        return true
    end

    -- legacy string spec => presence-only (optional via "?")
    if type(shape) == "string" then
        if value == nil then
            if spec_is_optional(shape) then
                return true
            end
            return false, string.format(
                "contract mismatch at '%s' (missing key)",
                path
            )
        end
        return true
    end

    -- nested table spec
    if type(shape) ~= "table" then
        return false, string.format(
            "invalid contract shape at '%s' (expected table/true/string, got %s)",
            path,
            type(shape)
        )
    end

    if type(value) ~= "table" then
        return false, string.format(
            "contract mismatch at '%s' (expected table)",
            path
        )
    end

    for raw_key, requirement in pairs(shape) do
        local key, key_optional = parse_key(raw_key)
        local child = value[key]

        if requirement == true then
            if child == nil and not key_optional then
                return false, string.format(
                    "contract mismatch at '%s.%s' (missing key)",
                    path,
                    key
                )
            end

        elseif type(requirement) == "table" then
            if child == nil then
                if not key_optional then
                    return false, string.format(
                        "contract mismatch at '%s.%s' (missing key)",
                        path,
                        key
                    )
                end
            else
                local ok, err = validate_shape(child, requirement, path .. "." .. key)
                if not ok then
                    return false, err
                end
            end

        elseif type(requirement) == "string" then
            -- legacy leaf string => presence-only (optional handled by key? or "type?")
            if child == nil and not (key_optional or spec_is_optional(requirement)) then
                return false, string.format(
                    "contract mismatch at '%s.%s' (missing key)",
                    path,
                    key
                )
            end
        else
            -- anything else => ignore
        end
    end

    return true
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param value any
---@param shape any
function Contract.assert(value, shape)
    local ok, err = validate_shape(value, shape)
    if not ok then
        error(err, 3)
    end
end

---@param value any
---@param shape any
---@return boolean ok
---@return string? err
function Contract.check(value, shape)
    return validate_shape(value, shape)
end

return Contract
