-- core/schema/engine/runtime/audit/audit.lua
--
-- Generic object auditing and schema comparison.

local Validate = require("core.schema.engine.runtime.validation")
local Inspect  = require("core.schema.engine.runtime.inspect")

local Resolver = require("core.schema.engine.runtime.resolver")
local State    = require("core.schema.engine.runtime.state")

local Printers = require("core.schema.engine.runtime.audit.printers")

local Audit = {}

------------------------------------------------------------
-- Schema diff
------------------------------------------------------------

function Audit.diff(domain, obj)

    local schema = Inspect.inspect(domain)

    if not schema then
        return nil, "unknown domain: " .. tostring(domain)
    end

    local expected = {}
    local missing  = {}
    local extra    = {}

    for _, field in ipairs(schema.fields) do
        expected[field.name] = true
    end

    for name in pairs(expected) do
        if obj[name] == nil then
            missing[#missing + 1] = name
        end
    end

    for k in pairs(obj or {}) do
        if not expected[k] then
            extra[#extra + 1] = k
        end
    end

    table.sort(missing)
    table.sort(extra)

    return {
        domain  = domain,
        missing = missing,
        extra   = extra,
    }
end

------------------------------------------------------------
-- Base audit
------------------------------------------------------------

function Audit.run(domain, obj)

    local exists_ok, exists_report = Validate.exists(domain, obj)
    local valid_ok, valid_report   = Validate.validate(domain, obj)

    local diff = Audit.diff(domain, obj)

    return {
        domain = domain,

        structure_ok  = exists_ok,
        validation_ok = valid_ok,

        missing_fields = exists_report and exists_report.missing or {},
        extra_fields   = exists_report and exists_report.extra or {},

        validation_errors = valid_report or {},

        diff = diff,
    }
end

------------------------------------------------------------
-- Deep audit (recursive)
------------------------------------------------------------

function Audit.deep(domain, obj)

    local result = Audit.run(domain, obj)
    result.children = {}

    if type(obj) ~= "table" then
        return result
    end

    ------------------------------------------------
    -- resolve domain fields once
    ------------------------------------------------

    local field_names = Resolver.domain_fields(domain)
    if not field_names then
        return result
    end

    ------------------------------------------------
    -- cache field descriptors
    ------------------------------------------------

    local fields = {}

    for i = 1, #field_names do
        local name = field_names[i]
        fields[i] = Resolver.field(domain, name)
    end

    ------------------------------------------------
    -- iterate fields
    ------------------------------------------------

    for i = 1, #fields do

        local f = fields[i]
        local v = obj[f.name]

        if v ~= nil then

            local ref = f.reference

            ------------------------------------------------
            -- only descend into object domains
            ------------------------------------------------

            if ref and State.fields[ref] then

                ------------------------------------------------
                -- single object
                ------------------------------------------------

                if type(v) == "table" and v[1] == nil then

                    result.children[f.name] =
                        Audit.deep(ref, v)

                ------------------------------------------------
                -- array of objects
                ------------------------------------------------

                elseif type(v) == "table" then

                    local list = {}
                    local n = #v

                    for j = 1, n do
                        list[j] = Audit.deep(ref, v[j])
                    end

                    result.children[f.name] = list
                end
            end
        end
    end

    return result
end

------------------------------------------------------------
-- Compare objects
------------------------------------------------------------

function Audit.compare(domain, a, b)

    local schema = Inspect.inspect(domain)

    if not schema then
        error("unknown domain: " .. domain)
    end

    local result = {
        domain = domain,
        differences = {}
    }

    for _, field in ipairs(schema.fields) do

        local name = field.name
        local va = a[name]
        local vb = b[name]

        if va ~= vb then
            result.differences[#result.differences + 1] = {
                field = name,
                a = va,
                b = vb
            }
        end
    end

    return result
end

------------------------------------------------------------
-- Dataset audit
------------------------------------------------------------

function Audit.dataset(domain, list)

    local errors = {}

    for i, obj in ipairs(list) do

        local report = Audit.run(domain, obj)

        if not report.structure_ok or not report.validation_ok then
            errors[#errors + 1] = {
                index = i,
                report = report
            }
        end
    end

    return {
        domain = domain,
        total  = #list,
        errors = errors,
        ok     = (#errors == 0)
    }
end

------------------------------------------------------------
-- Printers
------------------------------------------------------------

Audit.print  = Printers.print
Audit.tree   = Printers.tree
Audit.table  = Printers.table

-- legacy names
Audit.print_tree  = Printers.tree
Audit.print_table = Printers.table

return Audit
