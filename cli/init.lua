-- cli/init.lua

local Parser   = require("cli.parser")
local Registry = require("cli.registry")
local Context  = require("cli.context")
local Help     = require("cli.help")

-- Load domains (self-register)
require("cli.domains.ledger")

local CLI = {}

----------------------------------------------------------------
-- Help dispatch
----------------------------------------------------------------

function CLI.print_global_help()
    Help.print_global()
end

function CLI.print_domain_help(domain)
    Help.print_domain(domain)
end

function CLI.print_command_help(domain, action)
    Help.print_command(domain, action)
end

----------------------------------------------------------------
-- Main entry
----------------------------------------------------------------

function CLI.run(argv)
    argv = argv or {}

    local domains = Registry.domains_all()

    ----------------------------------------------------------------
    -- GLOBAL HELP (no args)
    ----------------------------------------------------------------
    if #argv == 0 then
        CLI.print_global_help()
        return
    end

    ----------------------------------------------------------------
    -- GLOBAL HELP (any leading dash: -h, --help, -help, etc)
    ----------------------------------------------------------------
    if argv[1]:sub(1, 1) == "-" then
        CLI.print_global_help()
        return
    end

    ----------------------------------------------------------------
    -- GLOBAL HELP (explicit)
    ----------------------------------------------------------------
    if argv[1] == "help" then
        CLI.print_global_help()
        return
    end

    ----------------------------------------------------------------
    -- UNKNOWN DOMAIN → global help + error
    ----------------------------------------------------------------
    local first = argv[1]
    if not domains[first] then
        io.stderr:write(
            string.format("error: unknown domain '%s'\n\n", tostring(first))
        )
        CLI.print_global_help()
        return
    end

    ----------------------------------------------------------------
    -- DOMAIN ONLY → domain help
    ----------------------------------------------------------------
    if #argv == 1 then
        CLI.print_domain_help(first)
        return
    end

    ----------------------------------------------------------------
    -- PARSE STRUCTURED COMMAND
    ----------------------------------------------------------------
    local parsed
    local ok, err = pcall(function()
        parsed = Parser.parse(argv)
    end)

    if not ok then
        io.stderr:write("error: " .. tostring(err) .. "\n\n")
        CLI.print_domain_help(first)
        return
    end

    local spec = Registry.resolve(parsed.domain, parsed.action)

    ----------------------------------------------------------------
    -- UNKNOWN ACTION → domain help
    ----------------------------------------------------------------
    if not spec then
        CLI.print_domain_help(parsed.domain)
        return
    end

    local ctx = Context.new(parsed)

    ----------------------------------------------------------------
    -- COMMAND HELP (explicit flag)
    ----------------------------------------------------------------
    if ctx.flags.help or ctx.flags.h then
        CLI.print_command_help(parsed.domain, parsed.action)
        return
    end

    ----------------------------------------------------------------
    -- EXECUTE (with usage fallback)
    ----------------------------------------------------------------
    local result = spec.run(ctx)

    -- Domain signaled "missing args / show usage"
    if type(result) == "table" and result.kind == "usage" then
        CLI.print_command_help(result.domain, result.action)
        return
    end

    return result
end

return CLI
