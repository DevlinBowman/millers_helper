local Registry = {}

Registry.rules = {
    quote   = "system.execution.rules.quote",
    compare = "system.execution.rules.compare",
}

function Registry.resolve(service)

    local path = Registry.rules[service]

    if not path then
        return { service }
    end

    local rule = require(path)

    return rule
end

return Registry
