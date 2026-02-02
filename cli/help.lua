-- cli/help.lua
--
-- CLI help renderer.
--
-- Responsibilities:
--   • Render global, domain, and command help
--   • Read command metadata from the registry
--   • Format usage, options, and examples
--   • Hide internal registry entries (e.g. _controller)
--
-- This module is presentation-only.
-- It does not influence command execution.

local Registry = require("cli.registry")

local Help = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function indent(n)
    return string.rep("    ", n)
end

local function extract_args(usage)
    if not usage then return "" end
    local _, _, rest = usage:find("^%S+%s+%S+%s*(.*)$")
    return rest or ""
end

local function print_options(opts, level)
    if not opts or #opts == 0 then
        print(indent(level) .. "(no options)")
        return
    end

    for _, opt in ipairs(opts) do
        print(string.format(
            "%s%-18s %s",
            indent(level),
            opt[1],
            opt[2]
        ))
    end
end

----------------------------------------------------------------
-- Recursive renderers
----------------------------------------------------------------

local function render_command(domain, name, spec, level)
    local h = spec.help or {}
    local args = extract_args(h.usage)

    print(string.format(
        "%s[ %s ] %s",
        indent(level),
        name,
        args
    ))

    print(indent(level + 1) .. "-- options:")
    print_options(h.options, level + 2)
    print("")
end

----------------------------------------------------------------
-- Entry points
----------------------------------------------------------------

function Help.print_global()
    print("Usage:")
    print("  lua main.lua <domain> <command> <args> <flags>\n")

    local domains = Registry.domains_all()
    local names = {}
    for d in pairs(domains) do
        names[#names + 1] = d
    end
    table.sort(names)

    for _, domain in ipairs(names) do
        Help.print_domain(domain, true)
    end
end

function Help.print_domain(domain, suppress_header)
    local actions = Registry.domains_all()[domain]
    if not actions then return end

    if not suppress_header then
        print("Usage:")
        print(string.format(
            "  lua main.lua %s <command> <args> <flags>\n",
            domain
        ))
    end

    print("[ " .. domain .. " ]")

    local names = {}
    for a in pairs(actions) do
        if a:sub(1, 1) ~= "_" then
            names[#names + 1] = a
        end
    end
    table.sort(names)

    for _, action in ipairs(names) do
        render_command(domain, action, actions[action], 1)
    end
end

function Help.print_command(domain, action)
    local spec = Registry.resolve(domain, action)
    if not spec then return end

    local h = spec.help or {}

    print("Usage:")
    print(string.format(
        "  lua main.lua %s %s %s\n",
        domain,
        action,
        extract_args(h.usage)
    ))

    print("[ " .. domain .. " " .. action .. " ]")
    print("    -- options:")
    print_options(h.options, 2)
end

return Help
