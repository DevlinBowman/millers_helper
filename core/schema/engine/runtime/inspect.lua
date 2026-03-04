-- core/schema/engine/runtime/inspect.lua
--
-- Semantic introspection utilities.
-- Fields are authoritative.
-- Shapes influence ordering only.

local State    = require("core.schema.engine.runtime.state")
local Resolver = require("core.schema.engine.runtime.resolver")

local Inspect = {}

------------------------------------------------------------
-- structured inspect
------------------------------------------------------------

function Inspect.inspect(domain)

    local function inspect_domain(d)

        local fields = Resolver.domain_fields(d)
        if not fields then return nil end

        local out = {
            domain = d,
            fields = {}
        }

        for _, name in ipairs(fields) do

            local f = Resolver.field(d, name)

            if f then

                local info = {
                    name        = f.name,
                    type        = f.type,
                    required    = f.required,
                    default     = f.default,
                    authority   = f.authority,
                    mutable     = f.mutable,
                    unit        = f.unit,
                    precision   = f.precision,
                    groups      = f.groups,
                    description = f.description
                }

                if f.reference then

                    local values = State.values[f.reference]

                    info.allowed_values = {}

                    if values then
                        for _, v in ipairs(values.list) do
                            info.allowed_values[#info.allowed_values + 1] = {
                                name        = v.name,
                                description = v.description
                            }
                        end
                    end
                end

                out.fields[#out.fields + 1] = info
            end
        end

        return out
    end

    ------------------------------------------------

    if domain then
        return inspect_domain(domain)
    end

    local tree = {}

    for d, _ in pairs(State.fields) do
        tree[d] = inspect_domain(d)
    end

    return tree
end

------------------------------------------------------------
-- compact tree renderer
------------------------------------------------------------

function Inspect.inspect_compact(domain)

    local function render_domain(d)

        local fields = Resolver.domain_fields(d)
        if not fields then return "" end

        local lines = {}
        lines[#lines + 1] = d

        ------------------------------------------------
        -- align fields
        ------------------------------------------------

        local max_len = 0

        for _, name in ipairs(fields) do
            if #name > max_len then
                max_len = #name
            end
        end

        local fmt = "\t%-" .. max_len .. "s | %s"

        ------------------------------------------------
        -- render fields
        ------------------------------------------------

        for _, name in ipairs(fields) do

            local f = Resolver.field(d, name)
            if not f then goto continue end

            lines[#lines + 1] =
                fmt:format(f.name, f.description or "")

            ------------------------------------------------
            -- values
            ------------------------------------------------

            if f.reference then

                local values = State.values[f.reference]

                if values and #values.list > 0 then

                    local names = {}

                    for _, v in ipairs(values.list) do
                        names[#names + 1] = v.name
                    end

                    table.sort(names)

                    lines[#lines + 1] =
                        "\t\tvalue : " .. table.concat(names, " | ")

                    lines[#lines + 1] = ""
                end
            end

            ::continue::
        end

        if lines[#lines] == "" then
            table.remove(lines)
        end

        return table.concat(lines, "\n")
    end

    ------------------------------------------------

    local output

    if domain then
        output = render_domain(domain)
    else

        local blocks = {}

        for d, _ in pairs(State.fields) do
            blocks[#blocks + 1] = render_domain(d)
        end

        table.sort(blocks)

        output = table.concat(blocks, "\n\n")
    end

    print(output)

    return output
end

return Inspect
