-- core/schema/engine/runtime/resolver.lua

local State = require("core.schema.engine.runtime.state")

local Resolver = {}

------------------------------------------------
-- domain fields
------------------------------------------------

-- core/schema/engine/runtime/resolver.lua
-- function: Resolver.domain_fields

function Resolver.domain_fields(domain)
    local field_node = State.fields[domain]
    if not field_node then
        return nil, false
    end

    -- authoritative field set (canonical names)
    local all = {}
    local present = {}
    for _, f in ipairs(field_node.list) do
        all[#all + 1] = f.name
        present[f.name] = true
    end

    -- shapes are ordering only
    local shape = State.shapes[domain]
    if not shape or type(shape.fields) ~= "table" then
        return all, false
    end

    local ordered = {}
    local used = {}

    -- 1) add fields listed in shape (only if they exist as real fields)
    for _, name in ipairs(shape.fields) do
        if present[name] and not used[name] then
            ordered[#ordered + 1] = name
            used[name] = true
        end
    end

    -- 2) append any remaining fields not mentioned in shape
    for _, name in ipairs(all) do
        if not used[name] then
            ordered[#ordered + 1] = name
            used[name] = true
        end
    end

    return ordered, true
end

------------------------------------------------
-- field lookup
------------------------------------------------

function Resolver.field(domain, name)

    local node = State.fields[domain]
    if not node then
        return nil
    end

    ------------------------------------------------
    -- canonical field name
    ------------------------------------------------

    local field = node.by_name[name]
    if field then
        return field
    end

    ------------------------------------------------
    -- alias lookup
    ------------------------------------------------

    local canonical = node.alias_to_name[name]

    if canonical then
        return node.by_name[canonical]
    end

    return nil
end

------------------------------------------------
-- reference resolution
------------------------------------------------

function Resolver.reference(reference, context_domain)

    if not reference then
        return nil
    end

    ------------------------------------------------
    -- fully qualified domain already
    ------------------------------------------------

    if State.values[reference] then
        return reference
    end

    ------------------------------------------------
    -- domain-relative lookup
    -- example:
    --   board + grade  -> board.grade
    ------------------------------------------------

    if context_domain then

        local candidate = context_domain .. "." .. reference

        if State.values[candidate] then
            return candidate
        end
    end

    ------------------------------------------------
    -- fallback
    ------------------------------------------------

    if State.values[reference] then
        return reference
    end

    return nil
end

------------------------------------------------
-- value lookup
------------------------------------------------

function Resolver.value(domain, key)

    local node = State.values[domain]

    if not node then
        return nil
    end

    ------------------------------------------------
    -- direct lookup (canonical + aliases)
    ------------------------------------------------

    local v = node.lookup[key]

    if v then
        return v
    end

    ------------------------------------------------
    -- lowercase lookup
    ------------------------------------------------

    if type(key) == "string" then
        return node.lookup[string.lower(key)]
    end

    return nil
end

return Resolver
