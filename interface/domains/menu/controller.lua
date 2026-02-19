-- interface/domains/menu/controller.lua

local Registry = require("interface.registry")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({
        history = {},
        current_domain = nil,
        sessions = {},
    }, Controller)
end

local function tokenize(input)
    local argv = {}
    for token in input:gmatch("%S+") do
        argv[#argv + 1] = token
    end
    return argv
end

local function print_domains()
    print("\nAvailable domains:")
    for name, _ in pairs(Registry.domains_all()) do
        if name ~= "menu" then
            print("  - " .. name)
        end
    end
    print("")
end

function Controller:run()
    local CLI = require("interface.shells.cli.init")

    print("\n=== Interactive Mode ===")
    print("Type 'help' for commands.\n")

    while true do

        local prompt_label = self.current_domain
            and (self.current_domain .. "> ")
            or "app> "

        io.write(prompt_label)
        local input = io.read()
        if not input then return end

        input = input:gsub("^%s+", ""):gsub("%s+$", "")
        if input == "" then goto continue end

        table.insert(self.history, input)

        --------------------------------------------------------
        -- Builtins
        --------------------------------------------------------

        if input == "exit" then return end

        if input == "clear" then
            os.execute("clear")
            goto continue
        end

        if input == "domains" then
            print_domains()
            goto continue
        end

        if input == "history" then
            for i, cmd in ipairs(self.history) do
                print(string.format("%02d  %s", i, cmd))
            end
            goto continue
        end

        if input == "help" then
            print([[
Built-in commands:
  domains
  use <domain>
  back
  history
  clear
  exit
]])
            goto continue
        end

        --------------------------------------------------------
        -- Domain Switching
        --------------------------------------------------------

        local use_domain = input:match("^use%s+(%S+)")
        if use_domain then
            if Registry.domains_all()[use_domain] then
                self.current_domain = use_domain
                print("Switched to domain:", use_domain)
            else
                print("Unknown domain:", use_domain)
            end
            goto continue
        end

        if input == "back" then
            self.current_domain = nil
            goto continue
        end

        --------------------------------------------------------
        -- Domain Interactive Delegation (FIXED)
        --------------------------------------------------------

        if self.current_domain then

            local domain_menu = require(
                "interface.domains." .. self.current_domain .. ".menu"
            )

            if domain_menu and domain_menu.handle then

                local controller = Registry.controller_for(self.current_domain)

                -- Correct call signature:
                -- handle(controller, line)
                domain_menu.handle(controller, input)

                goto continue
            end
        end

        --------------------------------------------------------
        -- Fallback → raw CLI execution
        --------------------------------------------------------

        local argv = tokenize(input)

        local ok, err = pcall(function()
            CLI.run(argv)
        end)

        if not ok then
            print("error:", err)
        end

        ::continue::
    end
end

return Controller
