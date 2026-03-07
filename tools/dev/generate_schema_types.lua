-- tools/dev/generate_schema_types.lua
--
-- Generates structured LuaLS types from schema runtime state.
-- Produces domain-aware autocomplete for:
--   • field domains
--   • value domains
--   • field names per domain
--   • enum symbols per domain
--
-- Output:
--   core/schema/api/types_generated.lua

local Engine = require("core.schema.engine.core")
local State  = require("core.schema.engine.runtime.state")

local OUTPUT = "core/schema/api/types_generated.lua"

------------------------------------------------
-- helpers
------------------------------------------------

local function sorted_keys(t)
    local out = {}
    for k in pairs(t) do
        out[#out+1] = k
    end
    table.sort(out)
    return out
end

local function sanitize(name)
    return name:gsub("%.", "_")
end

local function alias_block(name, values)

    if #values == 0 then
        return ""
    end

    local out = {}
    out[#out+1] = "---@alias " .. name

    for _, v in ipairs(values) do
        out[#out+1] = '---|"' .. v .. '"'
    end

    return table.concat(out, "\n")
end

local function write_file(path, content)
    local f = assert(io.open(path,"w"))
    f:write(content)
    f:close()
end

------------------------------------------------
-- collect field domains + names
------------------------------------------------

local field_domains = {}
local field_names_by_domain = {}

for domain, node in pairs(State.fields) do

    field_domains[#field_domains+1] = domain

    local names = {}
    for _, f in ipairs(node.list or {}) do
        names[#names+1] = f.name
    end

    table.sort(names)
    field_names_by_domain[domain] = names
end

table.sort(field_domains)

------------------------------------------------
-- collect value domains + enums
------------------------------------------------

local value_domains = {}
local enum_by_domain = {}

for domain, node in pairs(State.values) do

    value_domains[#value_domains+1] = domain

    local names = {}
    for _, v in ipairs(node.list or {}) do
        names[#names+1] = v.name
    end

    table.sort(names)
    enum_by_domain[domain] = names
end

table.sort(value_domains)

------------------------------------------------
-- build file
------------------------------------------------

local out = {}

out[#out+1] = "---@meta"
out[#out+1] = "-- AUTO-GENERATED FILE"
out[#out+1] = "-- Generated from schema runtime state"
out[#out+1] = "-- DO NOT EDIT"
out[#out+1] = ""

------------------------------------------------
-- field domains
------------------------------------------------

out[#out+1] = "------------------------------------------------"
out[#out+1] = "-- FIELD DOMAINS"
out[#out+1] = "------------------------------------------------"
out[#out+1] = ""

out[#out+1] = alias_block(
    "SchemaFieldDomain",
    field_domains
)

out[#out+1] = ""

------------------------------------------------
-- value domains
------------------------------------------------

out[#out+1] = "------------------------------------------------"
out[#out+1] = "-- VALUE DOMAINS"
out[#out+1] = "------------------------------------------------"
out[#out+1] = ""

out[#out+1] = alias_block(
    "SchemaValueDomain",
    value_domains
)

out[#out+1] = ""

------------------------------------------------
-- field names per domain
------------------------------------------------

out[#out+1] = "------------------------------------------------"
out[#out+1] = "-- FIELD NAMES"
out[#out+1] = "------------------------------------------------"
out[#out+1] = ""

for domain, names in pairs(field_names_by_domain) do

    local alias =
        "SchemaFieldName_" .. sanitize(domain)

    out[#out+1] =
        alias_block(alias, names)

    out[#out+1] = ""
end

------------------------------------------------
-- enum values per domain
------------------------------------------------

out[#out+1] = "------------------------------------------------"
out[#out+1] = "-- ENUM SYMBOLS"
out[#out+1] = "------------------------------------------------"
out[#out+1] = ""

for domain, values in pairs(enum_by_domain) do

    local alias =
        "SchemaEnum_" .. sanitize(domain)

    out[#out+1] =
        alias_block(alias, values)

    out[#out+1] = ""
end

------------------------------------------------
-- write file
------------------------------------------------

write_file(
    OUTPUT,
    table.concat(out,"\n")
)

print("Schema LSP types generated → " .. OUTPUT)
