-- core/schema/engine/runtime/domains.lua

local State = require("core.schema.engine.runtime.state")

local Domains = {}

------------------------------------------------
-- full metadata
------------------------------------------------

function Domains.list()

    local out = {}

    for d, node in pairs(State.values) do
        out[#out + 1] = { kind="value", domain=d, count=#node.list }
    end

    for d, node in pairs(State.fields) do
        out[#out + 1] = { kind="field", domain=d, count=#node.list }
    end

    for d, node in pairs(State.shapes) do
        out[#out + 1] = { kind="shape", domain=d, count=#node.fields }
    end

    return out
end

------------------------------------------------
-- domain names only
------------------------------------------------

function Domains.names()

    local out = {}

    for d, _ in pairs(State.fields) do
        out[#out + 1] = d
    end

    table.sort(out)

    return out
end

------------------------------------------------
-- grouped printer
------------------------------------------------

function Domains.print()

    local values = {}
    local fields = {}
    local shapes = {}

    for d in pairs(State.values) do values[#values+1] = d end
    for d in pairs(State.fields) do fields[#fields+1] = d end
    for d in pairs(State.shapes) do shapes[#shapes+1] = d end

    table.sort(values)
    table.sort(fields)
    table.sort(shapes)

    if #values > 0 then
        print("VALUES")
        for _, d in ipairs(values) do
            print("  " .. d)
        end
        print("")
    end

    if #fields > 0 then
        print("FIELDS")
        for _, d in ipairs(fields) do
            print("  " .. d)
        end
        print("")
    end

    if #shapes > 0 then
        print("SHAPES")
        for _, d in ipairs(shapes) do
            print("  " .. d)
        end
    end
end

return Domains
