-- core/schema/engine/core.lua

local Bootstrap = require("core.schema.engine.bootstrap")
local Registry  = require("core.schema.engine.registry")

local Indexer   = require("core.schema.engine.runtime.indexer")
local Domains   = require("core.schema.engine.runtime.domains")
local Inspect   = require("core.schema.engine.runtime.inspect")
local Validate  = require("core.schema.engine.runtime.validation")
local Resolver  = require("core.schema.engine.runtime.resolver")
local Catalog   = require("core.schema.engine.runtime.catalog")
local Audit     = require("core.schema.engine.runtime.audit")

local DTO       = require("core.schema.engine.dto")

local Core      = {}
Core.__index    = Core

------------------------------------------------
-- bootstrap
------------------------------------------------

for _, mod in ipairs(Bootstrap.values or {}) do
    Registry.register_standard(require(mod), mod)
end

for _, mod in ipairs(Bootstrap.fields or {}) do
    Registry.register_fields(require(mod), mod)
end

for _, mod in ipairs(Bootstrap.shapes or {}) do
    Registry.register_shapes(require(mod), mod)
end

------------------------------------------------
-- constructor
------------------------------------------------

function Core.new()

    Indexer.build()

    local self = setmetatable({}, Core)

    ------------------------------------------------
    -- validation
    ------------------------------------------------

    self.exists   = Validate.exists
    self.validate = Validate.validate
    self.check    = Validate.check

    ------------------------------------------------
    -- inspection
    ------------------------------------------------

    self.inspect         = Inspect.inspect
    self.inspect_compact = Inspect.inspect_compact

    ------------------------------------------------
    -- resolver (schema navigation)
    ------------------------------------------------

    self.field         = Resolver.field
    self.value         = Resolver.value
    self.domain_fields = Resolver.domain_fields
    self.reference     = Resolver.reference

    ------------------------------------------------
    -- value domain helpers
    ------------------------------------------------

    function self.domain_values(domain)
        local node = require("core.schema.engine.runtime.state").values[domain]
        if not node then
            return nil
        end
        return node.list
    end

    ------------------------------------------------
    -- template generation
    ------------------------------------------------

    function self.template(domain)

        local fields = Resolver.domain_fields(domain)

        if not fields then
            error("unknown domain: " .. tostring(domain))
        end

        local obj = {}

        for _, name in ipairs(fields) do

            local f = Resolver.field(domain, name)

            if f then
                obj[f.name] = f.default
            end

        end

        return obj
    end

    ------------------------------------------------
    -- domains
    ------------------------------------------------

    self.domains       = Domains.list
    self.domain_names  = Domains.names
    self.print_domains = Domains.print

    ------------------------------------------------
    -- DTO
    ------------------------------------------------

    function self.dto(domain, data)
        return DTO.new(domain, data)
    end

    ------------------------------------------------
    -- catalog
    ------------------------------------------------

    function self.catalog()
        return Catalog.new()
    end

    function self.get(name)
        return self.catalog():get(name)
    end

    function self.list(query)
        return self.catalog():list(query)
    end

    ------------------------------------------------
    -- audit
    ------------------------------------------------

    function self.audit(domain, obj)

        local report = Audit.run(domain, obj)

        return {

            report = report,

            deep = function()
                return Audit.deep(domain, obj)
            end,

            tree = function()
                Audit.print_tree(domain, obj)
            end,

            table = function()
                Audit.print_table(domain, obj)
            end,

            diff = function()
                return Audit.diff(domain, obj)
            end,

            compare = function(other)
                return Audit.compare(domain, obj, other)
            end

        }

    end

    function self.audit_dataset(domain, list)
        return Audit.dataset(domain, list)
    end

    return self
end

return Core.new()
