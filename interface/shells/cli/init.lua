-- interface/shells/cli/init.lua

local Parser   = require("interface.shells.cli.parser")
local Registry = require("interface.registry")
local Context  = require("interface.context")

-- Load domains
require("interface.domains.runtime")
require("interface.domains.ledger")
require("interface.domains.compare")

local CLI = {}

function CLI.run(argv)
    if #argv == 0 then
        print("usage: <domain> [command] [args]")
        return
    end

    local parsed = Parser.parse(argv)

    -- try explicit action first
    local spec = Registry.resolve(parsed.domain, parsed.action)

    ------------------------------------------------------------
    -- Default action fallback (no subcommand)
    ------------------------------------------------------------
    if not spec then
        spec = Registry.resolve(parsed.domain, nil)

        if spec then
            -- treat parsed.action as first positional
            if parsed.action ~= nil then
                table.insert(parsed.positionals, 1, parsed.action)
                parsed.action = nil
            end
        end
    end

    if not spec then
        io.stderr:write("unknown command\n")
        return
    end

    local controller = Registry.controller_for(parsed.domain)
    if not controller then
        io.stderr:write("unknown domain\n")
        return
    end

    local ctx = Context.new(parsed)

    return spec.run(ctx, controller)
end

return CLI
