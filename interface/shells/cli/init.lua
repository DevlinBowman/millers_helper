-- interface/shells/cli/init.lua
--
-- CLI entrypoint and top-level dispatcher.
--
-- Responsibilities:
--   • Load CLI domains (self-registering)
--   • Parse argv into structured intent
--   • Resolve domain, controller, and command
--   • Handle global / domain / command help
--   • Execute command adapters with injected controller
--
-- This file contains NO domain logic.
-- It is the orchestration shell for the CLI layer.

local Parser   = require("interface.shells.cli.parser")
local Registry = require("interface.registry")
local Context  = require("interface.context")
local Help     = require("interface.shells.cli.help")
local Completion = require("interface.shells.cli.completion")

-- Load domains (self-register)
require("interface.domains.ledger")
require("interface.domains.boards")
require("interface.domains.completions")

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

    if argv[1] == "__complete" then
        return Completion.run({ table.unpack(argv, 2) })
    end

    ----------------------------------------------------------------
    -- Global help (no args or help flags)
    ----------------------------------------------------------------

    if #argv == 0 then
        return CLI.print_global_help()
    end

    local first = argv[1]

    if first == "help" or first:sub(1, 1) == "-" then
        return CLI.print_global_help()
    end

    ----------------------------------------------------------------
    -- Domain validation
    ----------------------------------------------------------------

    local domains = Registry.domains_all()

    if not domains[first] then
        io.stderr:write(
            string.format("error: unknown domain '%s'\n\n", tostring(first))
        )
        return CLI.print_global_help()
    end

    ----------------------------------------------------------------
    -- Domain-only invocation → domain help
    ----------------------------------------------------------------

    if #argv == 1 then
        return CLI.print_domain_help(first)
    end

    ----------------------------------------------------------------
    -- Parse argv → structured intent
    ----------------------------------------------------------------

    local parsed
    local ok, err = pcall(function()
        parsed = Parser.parse(argv)
    end)

    if not ok then
        io.stderr:write("error: " .. tostring(err) .. "\n\n")
        return CLI.print_domain_help(first)
    end

    ----------------------------------------------------------------
    -- Resolve command spec
    ----------------------------------------------------------------

    local spec = Registry.resolve(parsed.domain, parsed.action)

    if not spec then
        return CLI.print_domain_help(parsed.domain)
    end

    ----------------------------------------------------------------
    -- Build execution context
    ----------------------------------------------------------------

    local ctx = Context.new(parsed)

    ----------------------------------------------------------------
    -- Command-specific help
    ----------------------------------------------------------------

    if ctx.flags.help or ctx.flags.h then
        return CLI.print_command_help(parsed.domain, parsed.action)
    end

    ----------------------------------------------------------------
    -- Resolve controller (one per invocation)
    ----------------------------------------------------------------

    local controller = Registry.controller_for(parsed.domain)
    if not controller then
        ctx:die("no controller registered for domain: " .. parsed.domain)
    end

    ----------------------------------------------------------------
    -- Execute command adapter
    ----------------------------------------------------------------

    local result = spec.run(ctx, controller)

    ----------------------------------------------------------------
    -- Usage fallback
    ----------------------------------------------------------------

    if type(result) == "table" and result.kind == "usage" then
        return CLI.print_command_help(result.domain, result.action)
    end

    return result
end

return CLI
