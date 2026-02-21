local Inspector = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function indent(level)
    return string.rep("  ", level)
end

local function collect_value_entries(section)
    local values = {}

    for _, def in pairs(section) do
        if type(def) == "table" and def.kind == "value" then
            values[#values + 1] = def.value
        end
    end

    table.sort(values)
    return values
end

local function format_values(values)
    if not values then
        return "[ 'any' ]"
    end

    return "[ '" .. table.concat(values, "' | '") .. "' ]"
end

local function build_key_map(enum_module)
    local key_map = {}

    -- 1) Register canonical keys
    if type(enum_module.KEYS) == "table" then
        for _, def in pairs(enum_module.KEYS) do
            if def.kind == "key" then
                key_map[def.value] = { values = nil }
            end
        end
    end

    -- 2) Attach controlled values
    for section_name, section in pairs(enum_module) do
        if section_name ~= "KEYS" and type(section) == "table" then
            local values = collect_value_entries(section)

            if #values > 0 then
                local target = string.lower(section_name)

                if key_map[target] then
                    key_map[target].values = values
                end
            end
        end
    end

    return key_map
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

function Inspector.print_domain(domain_name, enum_module)
    print(domain_name)

    local key_map = build_key_map(enum_module)

    local keys = {}
    for k in pairs(key_map) do
        keys[#keys + 1] = k
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
        local values = key_map[key].values
        print(indent(1) .. string.format("%-14s %s", key, format_values(values)))
    end
end

function Inspector.print_all(enums_index)
    local domains = {}

    for name in pairs(enums_index) do
        domains[#domains + 1] = name
    end

    table.sort(domains)

    for i, domain in ipairs(domains) do
        Inspector.print_domain(domain, enums_index[domain])
        if i < #domains then
            print("")
        end
    end
end

return Inspector
