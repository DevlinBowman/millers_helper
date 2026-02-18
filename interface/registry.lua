-- interface/registry.lua

local Registry = {
    domains = {}
}

local DEFAULT_ACTION = "__default"

function Registry.register_domain(name, controller)
    Registry.domains[name] = {
        _controller = controller,
    }
end

function Registry.register(domain, action, spec)
    local d = Registry.domains[domain]
    if not d then
        error("domain not registered: " .. tostring(domain))
    end

    if action == nil then
        action = DEFAULT_ACTION
    end

    d[action] = spec
end

function Registry.controller_for(domain)
    local d = Registry.domains[domain]
    if not d then return nil end
    return d._controller.new()
end

function Registry.resolve(domain, action)
    local d = Registry.domains[domain]
    if not d then return nil end

    if action == nil then
        return d[DEFAULT_ACTION]
    end

    return d[action]
end

function Registry.domains_all()
    return Registry.domains
end

return Registry
