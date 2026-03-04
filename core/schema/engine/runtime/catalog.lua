-- core/engine/runtime/catalog.lua
--
-- Cross-domain schema query system.
-- Provides semantic search over fields and values.

local State = require("core.engine.runtime.state")

local Catalog = {}
Catalog.__index = Catalog

------------------------------------------------
-- build flattened item list
------------------------------------------------

local function collect()

    local items = {}

    ------------------------------------------------
    -- fields
    ------------------------------------------------

    for domain, node in pairs(State.fields) do
        for _, f in ipairs(node.list) do
            items[#items + 1] = f
        end
    end

    ------------------------------------------------
    -- values
    ------------------------------------------------

    for domain, node in pairs(State.values) do
        for _, v in ipairs(node.list) do
            items[#items + 1] = v
        end
    end

    return items
end

------------------------------------------------
-- generic matcher
------------------------------------------------

local function match(item, query)

    for k, v in pairs(query) do

        local field = item[k]

        if field == nil then
            return false
        end

        if type(field) == "table" then

            local ok = false

            for _, x in ipairs(field) do
                if x == v then
                    ok = true
                    break
                end
            end

            if not ok then return false end

        elseif field ~= v then
            return false
        end
    end

    return true
end

------------------------------------------------
-- constructor
------------------------------------------------

function Catalog.new()
    return setmetatable({
        items = collect()
    }, Catalog)
end

------------------------------------------------
-- list items matching filter
------------------------------------------------

function Catalog:list(query)

    query = query or {}

    local out = {}

    for _, item in ipairs(self.items) do
        if match(item, query) then
            out[#out + 1] = item
        end
    end

    return out
end

------------------------------------------------
-- get item by name
------------------------------------------------

function Catalog:get(name)

    for _, item in ipairs(self.items) do
        if item.name == name then
            return item
        end
    end

    return nil
end

------------------------------------------------
-- list domains
------------------------------------------------

function Catalog:domains()

    local set = {}

    for _, item in ipairs(self.items) do
        set[item.domain] = true
    end

    local out = {}

    for d, _ in pairs(set) do
        out[#out + 1] = d
    end

    table.sort(out)

    return out
end

return Catalog
