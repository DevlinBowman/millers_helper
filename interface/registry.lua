-- interface/registry.lua
--
-- CLI domain and command registry.
--
-- Responsibilities:
--   • Register domains and their controllers
--   • Register commands under each domain
--   • Resolve commands at runtime
--   • Provide controller instances per domain
--
-- The registry is a structural index only.
-- It contains no execution logic.

local Registry = {
    domains = {}
}

----------------------------------------------------------------
-- Domain registration
----------------------------------------------------------------

function Registry.register_domain(domain, opts)
    assert(type(domain) == "string", "domain required")
    assert(type(opts) == "table", "opts required")

    Registry.domains[domain] = Registry.domains[domain] or {}
    Registry.domains[domain]._controller = opts.controller
end

function Registry.controller_for(domain)
    local d = Registry.domains[domain]
    if not d or not d._controller then
        return nil
    end
    return d._controller.new()
end

----------------------------------------------------------------
-- Command registration
----------------------------------------------------------------

function Registry.register(domain, action, spec)
    assert(type(domain) == "string", "domain required")
    assert(type(action) == "string", "action required")
    assert(type(spec) == "table", "spec required")
    assert(type(spec.run) == "function", "spec.run required")

    Registry.domains[domain] = Registry.domains[domain] or {}
    Registry.domains[domain][action] = spec
end

function Registry.resolve(domain, action)
    local d = Registry.domains[domain]
    return d and d[action]
end

function Registry.domains_all()
    return Registry.domains
end

return Registry
