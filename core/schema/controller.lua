-- core/schema/controller.lua
--
-- Schema Domain Controller
--
-- Responsibilities:
--   • Provide stable public API
--   • Wrap engine calls with SchemaResult DTO façade
--   • Prevent consumers from importing runtime subsystems
--
-- Architecture:
--   controller → engine → runtime.*

local Registry = require("core.schema.registry")
local Result   = require("core.schema.result")

local Controller = {}

------------------------------------------------
-- internal helper
------------------------------------------------

local function wrap(data)
    return Result.new(data)
end

------------------------------------------------
-- engine passthrough (debug / advanced usage)
------------------------------------------------

function Controller.engine()
    return Registry.engine
end

------------------------------------------------
-- value access
------------------------------------------------

function Controller.value(domain, key)
    return wrap({
        value = Registry.engine.value(domain, key)
    })
end

function Controller.values(domain)
    return wrap({
        values = Registry.engine.domain_values(domain)
    })
end

------------------------------------------------
-- field access
------------------------------------------------

function Controller.field(domain, name)
    return wrap({
        field = Registry.engine.field(domain, name)
    })
end

------------------------------------------------
-- template generation
------------------------------------------------

function Controller.template(domain)
    return wrap({
        template = Registry.engine.template(domain)
    })
end

------------------------------------------------
-- DTO
------------------------------------------------

function Controller.dto(domain, data)
    return wrap({
        dto = Registry.engine.dto(domain, data)
    })
end

------------------------------------------------
-- audit
------------------------------------------------

function Controller.audit(domain, obj)
    return wrap({
        audit = Registry.engine.audit(domain, obj)
    })
end

------------------------------------------------
-- schema inspection
------------------------------------------------

function Controller.inspect(domain)
    return wrap({
        inspect = Registry.engine.inspect(domain)
    })
end

function Controller.inspect_compact(domain)
    return wrap({
        inspect = Registry.engine.inspect_compact(domain)
    })
end

------------------------------------------------
-- validation
------------------------------------------------

function Controller.exists(domain, obj)
    return wrap({
        exists = Registry.engine.exists(domain, obj)
    })
end

function Controller.validate(domain, obj)
    return wrap({
        validate = Registry.engine.validate(domain, obj)
    })
end

function Controller.check(domain, obj)
    return wrap({
        check = Registry.engine.check(domain, obj)
    })
end

------------------------------------------------
-- domain metadata
------------------------------------------------

function Controller.domains()
    return wrap({
        domains = Registry.engine.domains()
    })
end

function Controller.domain_names()
    return wrap({
        domain_names = Registry.engine.domain_names()
    })
end

------------------------------------------------
-- catalog query
------------------------------------------------

function Controller.catalog()
    return wrap({
        catalog = Registry.engine.catalog()
    })
end

function Controller.get(name)
    return wrap({
        item = Registry.engine.get(name)
    })
end

function Controller.list(query)
    return wrap({
        items = Registry.engine.list(query)
    })
end

------------------------------------------------
-- dataset audit
------------------------------------------------

function Controller.audit_dataset(domain, list)
    return wrap({
        dataset = Registry.engine.audit_dataset(domain, list)
    })
end

------------------------------------------------
-- RAW ACCESS (internal domains use this)
------------------------------------------------

function Controller.value_raw(domain, key)
    return Registry.engine.value(domain, key)
end

function Controller.values_raw(domain)
    return Registry.engine.domain_values(domain)
end

function Controller.field_raw(domain, name)
    return Registry.engine.field(domain, name)
end

function Controller.template_raw(domain)
    return Registry.engine.template(domain)
end

return Controller
