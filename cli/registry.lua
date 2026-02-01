-- cli/registry.lua

local Registry = {
    domains = {}
}

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
