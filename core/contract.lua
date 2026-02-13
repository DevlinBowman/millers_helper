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

---@param t any
---@return string
local function keys_of(t)
    if type(t) ~= "table" then
        return tostring(t)
    end
    local out = {}
    for k in pairs(t) do
        out[#out + 1] = tostring(k)
    end
    table.sort(out)
    return table.concat(out, ", ")
end

---@param path string
---@param expected any
---@param actual any
---@return string
local function format_missing(path, expected, actual)
    return string.format(
        "contract mismatch at '%s'\n  expected keys: {%s}\n  keys received: {%s}",
        path,
        keys_of(expected),
        keys_of(actual)
    )
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

    -- nil/false shape means ignore
    if shape == nil or shape == false then
        return true
    end

    -- legacy string spec => presence-only
    if type(shape) == "string" then
        if value == nil and not spec_is_optional(shape) then
            return false, string.format(
                "contract mismatch at '%s' (missing value)",
                path
            )
        end
        return true
    end

    -- invalid shape definition
    if type(shape) ~= "table" then
        return false, string.format(
            "invalid contract shape at '%s' (expected table/true/string, got %s)",
            path,
            type(shape)
        )
    end

    -- expected table but got something else
    if type(value) ~= "table" then
        return false, string.format(
            "contract mismatch at '%s' (expected table, got %s)",
            path,
            type(value)
        )
    end

    for raw_key, requirement in pairs(shape) do
        local key, key_optional = parse_key(raw_key)
        local child = value[key]
        local child_path = path .. "." .. key

        -- required presence
        if requirement == true then
            if child == nil and not key_optional then
                return false, format_missing(child_path, shape, value)
            end

        -- nested table
        elseif type(requirement) == "table" then
            if child == nil then
                if not key_optional then
                    return false, format_missing(child_path, requirement, value)
                end
            else
                local ok, err = validate_shape(child, requirement, child_path)
                if not ok then
                    return false, err
                end
            end

        -- string leaf (presence-only)
        elseif type(requirement) == "string" then
            if child == nil and not (key_optional or spec_is_optional(requirement)) then
                return false, format_missing(child_path, shape, value)
            end
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
