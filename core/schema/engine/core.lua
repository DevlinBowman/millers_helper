-- core/engine/core.lua

local Bootstrap = require("core.engine.bootstrap")
local Registry  = require("core.engine.registry")

local Indexer   = require("core.engine.runtime.indexer")
local Domains   = require("core.engine.runtime.domains")
local Inspect   = require("core.engine.runtime.inspect")
local Validate  = require("core.engine.runtime.validation")
local Resolver  = require("core.engine.runtime.resolver")
local Catalog   = require("core.engine.runtime.catalog")
local Audit     = require("core.engine.runtime.audit")

local DTO       = require("core.engine.dto")

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

    local self           = setmetatable({}, Core)

    ------------------------------------------------
    -- validation
    ------------------------------------------------

    self.exists          = Validate.exists
    self.validate        = Validate.validate
    self.check           = Validate.check

    ------------------------------------------------
    -- inspection
    ------------------------------------------------

    self.inspect         = Inspect.inspect
    self.inspect_compact = Inspect.inspect_compact

    ------------------------------------------------
    -- schema access
    ------------------------------------------------

    function self.field(domain, name)
        return Resolver.field(domain, name)
    end

    function self.domain_fields(domain)
        return Resolver.domain_fields(domain)
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
    -- DTO creation
    ------------------------------------------------

    function self.dto(domain, data)
        return DTO.new(domain, data)
    end

    ------------------------------------------------
    -- catalog / semantic query system
    ------------------------------------------------

    function self.catalog()
        return Catalog.new()
    end

    function self.get(query)
        return self.catalog():get(query)
    end

    function self.list(query)
        return self.catalog():list(query)
    end

    ------------------------------------------------
    -- auditing / comparison tools
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
