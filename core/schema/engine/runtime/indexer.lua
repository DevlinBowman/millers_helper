-- core/engine/runtime/indexer.lua

local Registry = require("core.engine.registry")
local State    = require("core.engine.runtime.state")

local Indexer = {}

function Indexer.build()

    ------------------------------------------------
    -- values
    ------------------------------------------------

    for domain, records in pairs(Registry._values) do

        local node = { lookup = {}, list = {} }

        for _, r in ipairs(records) do

            table.insert(node.list, r)

            ------------------------------------------------
            -- canonical name
            ------------------------------------------------

            node.lookup[r.name] = r

            ------------------------------------------------
            -- lowercase canonical
            ------------------------------------------------

            if type(r.name) == "string" then
                node.lookup[string.lower(r.name)] = r
            end

            ------------------------------------------------
            -- aliases
            ------------------------------------------------

            if r.aliases then
                for _, a in ipairs(r.aliases) do

                    node.lookup[a] = r

                    if type(a) == "string" then
                        node.lookup[string.lower(a)] = r
                    end

                end
            end

        end

        State.values[domain] = node

    end

    ------------------------------------------------
    -- fields
    ------------------------------------------------

    for domain, records in pairs(Registry._fields) do

        local node = { by_name = {}, list = {}, alias_to_name = {} }

        for _, r in ipairs(records) do

            ------------------------------------------------
            -- reference validation
            ------------------------------------------------

            if r.reference ~= nil then

                local value_domain_exists = State.values[r.reference] ~= nil
                local field_domain_exists = Registry._fields[r.reference] ~= nil

                if not value_domain_exists and not field_domain_exists then

                    local msg = ([[
[field reference rule violation]

rule: IF field.reference THEN field.reference must resolve to a value.domain OR field.domain

field: %s.%s
module: %s
received reference: %s

expected reference to match one of:

value domains: board.surface | order.status | allocation.basis ...

field domains: board | order | allocation_entry | ...

suggestion:
    check bootstrap registration for:

        core.values.%s
        core.fields.%s
]]):format(
                        r.domain or "unknown",
                        r.name or "unknown",
                        (r.__source and r.__source.module) or "unknown",
                        tostring(r.reference),
                        tostring(r.reference),
                        tostring(r.reference)
                    )

                    error(msg)
                end
            end

            ------------------------------------------------
            -- register field
            ------------------------------------------------

            table.insert(node.list, r)
            node.by_name[r.name] = r

            ------------------------------------------------
            -- aliases
            ------------------------------------------------

            if r.aliases then
                for _, a in ipairs(r.aliases) do

                    node.alias_to_name[a] = r.name

                    if type(a) == "string" then
                        node.alias_to_name[string.lower(a)] = r.name
                    end

                end
            end

        end

        State.fields[domain] = node

    end

    ------------------------------------------------
    -- shapes
    ------------------------------------------------

    for domain, shape in pairs(Registry._shapes) do

        local lookup = {}

        for _, name in ipairs(shape.fields or {}) do
            lookup[name] = true
        end

        State.shapes[domain] = {
            fields = shape.fields,
            lookup = lookup,
            __raw  = shape
        }

    end

end

return Indexer
