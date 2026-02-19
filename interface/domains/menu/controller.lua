-- interface/domains/menu/controller.lua

local Registry     = require("interface.registry")

local Controller   = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({
        history = {},
    }, Controller)
end

local function tokenize(input)
    local argv = {}
    for token in input:gmatch("%S+") do
        argv[#argv + 1] = token
    end
    return argv
end

local function print_help()
    print([[
app commands:
  ledger        enter ledger menu
  compare ...
  exit
]])
end

function Controller:run()
    print("\n=== Interactive Mode ===")

    while true do
        io.write("app> ")
        local input = io.read()
        if not input then return end

        input = input:gsub("^%s+", ""):gsub("%s+$", "")
        if input == "" then goto continue end

        if input == "q" or input == "exit" then
            require("interface.quit").now()
        end

        if input == "help" then
            print_help()
            goto continue
        end

        --------------------------------------------------------
        -- Enter Ledger Menu
        --------------------------------------------------------

        if input == "ledger" then
            local menu = require("interface.domains.ledger.menu")
            menu.run()
            goto continue
        end

        --------------------------------------------------------
        -- Default: CLI execution
        --------------------------------------------------------

        local argv = tokenize(input)

        local ok, err = pcall(function()
            local CLI = require("interface.shells.cli.init")
            CLI.run(argv)
        end)

        if not ok then
            print("error:", err)
        end

        ::continue::
    end
end

return Controller
