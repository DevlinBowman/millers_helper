-- core/engine/runtime/validation.lua
--
-- Structural and semantic validation layer.
-- Fields remain authoritative; shapes are optional.

local State    = require("core.engine.runtime.state")
local Resolver = require("core.engine.runtime.resolver")

local Validation = {}

------------------------------------------------
-- type checks
------------------------------------------------

local function type_ok(expected, v)
    if v == nil then return true end
    if expected == "symbol"  then return type(v) == "string" end
    if expected == "number"  then return type(v) == "number" end
    if expected == "string"  then return type(v) == "string" end
    if expected == "boolean" then return type(v) == "boolean" end
    if expected == "table"   then return type(v) == "table" end
    return false
end

------------------------------------------------
-- exists (structure)
------------------------------------------------

function Validation.exists(domain, object)

    if type(domain) == "table" then
        object = domain
        domain = "board"
    end

    if type(object) ~= "table" then
        return false, { error = "Object must be table" }
    end

    local fields = Resolver.domain_fields(domain)
    local field_node = State.fields[domain]

    if not fields and not field_node then
        return false, { error = "Unknown domain: " .. tostring(domain) }
    end

    local missing = {}
    local extra   = {}

    if fields then
        for _, name in ipairs(fields) do
            local f = Resolver.field(domain, name)
            if f and f.required and object[f.name] == nil then
                missing[#missing + 1] = f.name
            end
        end
    else
        for _, f in ipairs(field_node.list) do
            if f.required and object[f.name] == nil then
                missing[#missing + 1] = f.name
            end
        end
    end

    for key, _ in pairs(object) do
        if not Resolver.field(domain, key) then
            extra[#extra + 1] = key
        end
    end

    return (#missing == 0 and #extra == 0), {
        missing = missing,
        extra   = extra
    }
end

------------------------------------------------
-- validate values
------------------------------------------------

function Validation.validate(domain, object)

    if type(domain) == "table" then
        object = domain
        domain = "board"
    end

    if type(object) ~= "table" then
        return false, { "Object must be table" }
    end

    local fields = Resolver.domain_fields(domain)
    if not fields then
        return false, { "Unknown domain: " .. tostring(domain) }
    end

    local errors = {}

    for _, name in ipairs(fields) do
        local f = Resolver.field(domain, name)
        local v = object[f.name]

        ------------------------------------------------
        -- required
        ------------------------------------------------

        if f.required and v == nil then
            errors[#errors+1] = "Missing required: " .. f.name
        end

        ------------------------------------------------
        -- primitive type check (fallback only)
        ------------------------------------------------

        if v ~= nil and not type_ok(f.type, v) then
            errors[#errors+1] = "Invalid type for " .. f.name
            goto continue
        end

        ------------------------------------------------
        -- schema reference validation
        ------------------------------------------------

        local ref = f.reference
        if v ~= nil and ref then

            local value_domain = State.values[ref]
            local field_domain = State.fields[ref]

            ------------------------------------------------
            -- value universe
            ------------------------------------------------

            if value_domain then
                local enum = Resolver.value(ref, v)
                if not enum then
                    errors[#errors+1] = "Invalid value for " .. f.name
                end

            ------------------------------------------------
            -- object domain
            ------------------------------------------------

            elseif field_domain then
                if type(v) ~= "table" then
                    errors[#errors+1] = "Expected object for " .. f.name
                end

            ------------------------------------------------
            -- schema error
            ------------------------------------------------

            else
                errors[#errors+1] = "Unknown reference domain for " .. f.name
            end
        end

        ::continue::
    end

    return (#errors == 0), errors
end

------------------------------------------------
-- strict check
------------------------------------------------

function Validation.check(domain, object)

    local ok_exists, report_exists = Validation.exists(domain, object)
    if not ok_exists then
        return false, {
            type   = "structure",
            report = report_exists
        }
    end

    local ok_valid, report_valid = Validation.validate(domain, object)
    if not ok_valid then
        return false, {
            type   = "validation",
            report = report_valid
        }
    end

    return true, nil
end

return Validation
