-- interface/shells/tui/init.lua
--
-- TUI shell entrypoint.
--
-- Responsibilities:
--   • Load interface domains (self-register into registry)
--   • Route user intent (menu-driven)
--   • Invoke existing command adapters
--   • Never call services directly

-- Load domains (self-register) BEFORE touching the registry.
-- This mirrors interface/shells/cli/init.lua lifecycle.
require("interface.domains.ledger")
require("interface.domains.boards")

-- interface/shells/tui/init.lua

local Registry = require("interface.registry")
local Context  = require("interface.context")
local Router   = require("interface.shells.tui.router")
local UI       = require("interface.shells.tui.ui")

local TUI = {}

function TUI.run(argv)
    while true do
        local intent = Router.run()
        if not intent then
            UI.clear()
            return
        end

        local parsed = {
            domain      = intent.domain,
            action      = intent.action,
            positionals = intent.positionals,
            flags       = intent.flags,
            raw         = argv,
        }

        local ctx = Context.new(parsed)
        local controller = Registry.controller_for(parsed.domain)
        local spec = Registry.resolve(parsed.domain, parsed.action)

        UI.clear()

        local ok, err = pcall(function()
            spec.run(ctx, controller)
        end)

        if not ok then
            UI.error(err)
        else
            UI.pause()
        end
    end
end

return TUI
