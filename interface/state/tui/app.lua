-- interface/tui/app.lua

local Menu     = require("interface.tui.menu")
local Services = require("interface.tui.services")

local App = {}

local function load_domains()
    -- domains are specs; keep this explicit for now
    return {
        require("interface.tui.domains.ledger"),
        -- add compare later as a spec
    }
end

function App.run(opts)
    opts = opts or {}
    local services = Services.build({
        state_path = os.getenv("HOME") .. "/.lumber_app_state.lua",
    })

    local domains = load_domains()

    local function help_text()
        local lines = {"root menu:"}
        for _, d in ipairs(domains) do
            lines[#lines + 1] = "  " .. d.name .. "  -  " .. (d.description or "")
        end
        lines[#lines + 1] = "  q     - quit"
        return table.concat(lines, "\n")
    end

    local root = Menu.new({
        title = "Interactive",
        prompt = "app> ",
        help = help_text,
        ctx = { services = services, domains = domains },
        on_line = function(ctx, line)
            if line == "domains" then
                print(help_text())
                return
            end

            for _, d in ipairs(domains) do
                if line == d.name then
                    return d.menu(ctx.services):run()
                end
            end

            print("unknown command. try: domains or help")
        end
    })

    return root:run()
end

return App
