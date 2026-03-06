-- core/schema/engine/runtime/audit/capabilities.lua
--
-- Sparse capability scanner.
--
-- Produces a repair-oriented diff tree describing only
-- fields that are incomplete relative to schema definition.
--
-- Rules
--   nil       -> "nil"
--   0         -> "0"
--   "" / {}   -> "empty"
--   otherwise -> "complete"
--
-- Recursion only occurs when a field references a field-domain.

local Resolver = require("core.schema.engine.runtime.resolver")
local State    = require("core.schema.engine.runtime.state")

local Capabilities = {}

------------------------------------------------------------
-- atomic state classifier
------------------------------------------------------------

local function classify_state(value)

    if value == nil then
        return "nil"
    end

    if type(value) == "number" and value == 0 then
        return "0"
    end

    if type(value) == "string" and value == "" then
        return "empty"
    end

    if type(value) == "table" and next(value) == nil then
        return "empty"
    end

    return "complete"
end

------------------------------------------------------------
-- array detection
------------------------------------------------------------

local function is_array(value)
    return type(value) == "table" and value[1] ~= nil
end

------------------------------------------------------------
-- minimal schema projection
------------------------------------------------------------

local function field_meta(field)

    return {
        name     = field.name,
        required = field.required or false,
        groups   = field.groups or {},
        reference = field.reference,
        authority = field.authority,
    }
end

------------------------------------------------------------
-- compute aggregate state
------------------------------------------------------------

local function compute_state(fields)

    for _, node in pairs(fields) do
        if node.state ~= "complete" then
            return "sparse"
        end
    end

    return "complete"
end

------------------------------------------------------------
-- scan object
------------------------------------------------------------

local function scan_object(domain, obj)

    local field_names = Resolver.domain_fields(domain)

    if not field_names then
        return nil
    end

    if type(obj) ~= "table" then
        return {
            domain = domain,
            state  = "invalid",
        }
    end

    local report = {
        domain = domain,
        state  = "complete",
        fields = {}
    }

    ------------------------------------------------------------
    -- iterate schema fields
    ------------------------------------------------------------

    for _, fname in ipairs(field_names) do

        local field = Resolver.field(domain, fname)

        if not field then
            goto continue
        end

        local value = obj[field.name]
        local state = classify_state(value)

        --------------------------------------------------------
        -- stop immediately on missing parent
        --------------------------------------------------------

        if state ~= "complete" then

            report.fields[field.name] = {
                name     = field.name,
                state    = state,
                required = field.required or false,
                groups   = field.groups or {},
            }

            goto continue
        end

        --------------------------------------------------------
        -- primitive leaf
        --------------------------------------------------------

        if not field.reference then
            goto continue
        end

        --------------------------------------------------------
        -- enum domain → leaf
        --------------------------------------------------------

        if State.values[field.reference] then
            goto continue
        end

        --------------------------------------------------------
        -- object domain recursion
        --------------------------------------------------------

        if State.fields[field.reference] then

            ----------------------------------------------------
            -- array of objects
            ----------------------------------------------------

            if is_array(value) then

                local items = {}
                local sparse = false

                for index, item in ipairs(value) do

                    local child = scan_object(field.reference, item)

                    if child and child.state ~= "complete" then
                        items[index] = child
                        sparse = true
                    end

                end

                if sparse then

                    report.fields[field.name] = {
                        name  = field.name,
                        state = "sparse",
                        items = items,
                    }

                end

                goto continue
            end

            ----------------------------------------------------
            -- single object
            ----------------------------------------------------

            if type(value) == "table" then

                local child = scan_object(field.reference, value)

                if child and child.state ~= "complete" then

                    report.fields[field.name] = {
                        name  = field.name,
                        state = "sparse",
                        child = child
                    }

                end

            end
        end

        ::continue::
    end

    ------------------------------------------------------------
    -- prune empty objects
    ------------------------------------------------------------

    if next(report.fields) == nil then
        return {
            domain = domain,
            state  = "complete"
        }
    end

    report.state = compute_state(report.fields)

    return report
end

------------------------------------------------------------
-- public API
------------------------------------------------------------

function Capabilities.scan(domain, object)

    if type(object) ~= "table" then
        return {
            domain = domain,
            state  = "invalid"
        }
    end

    return scan_object(domain, object)
end

return Capabilities
