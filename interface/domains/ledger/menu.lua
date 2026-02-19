-- interface/domains/ledger/menu.lua
--
-- Interactive ledger menu (delegates through CLI)

local CLI     = require("interface.shells.cli.init")
local Session = require("interface.session")

local M       = {}

local function tokenize(input)
    local argv = {}
    for token in input:gmatch("%S+") do
        argv[#argv + 1] = token
    end
    return argv
end

local function print_help()
    print([[
ledger menu:
  set <path>          set ledger path
  show                show current ledger
  inspect             list transactions
  open <id|index>
  ingest <path>
  browser
  back
]])
end

function M.run()
    print("\n=== Ledger Menu ===")

    while true do
        local current = Session.get_ledger_path()
        local label = current and ("ledger(" .. current .. ")> ")
            or "ledger(no-ledger)> "

        io.write(label)
        local input = io.read()
        if not input then return end

        input = input:gsub("^%s+", ""):gsub("%s+$", "")
        if input == "" then goto continue end

        if input == "back" then
            return
        end

        if input == "q" or input == 'exit' then
            require("interface.quit").now()
        end

        if input == "help" then
            print_help()
            goto continue
        end

        --------------------------------------------------------
        -- Native menu commands
        --------------------------------------------------------

        if input:match("^set%s+") then
            local path = input:match("^set%s+(.+)")
            if path then
                Session.set_ledger_path(path)
                print("ledger set:", path)
            end
            goto continue
        end

        if input == "show" then
            local path = Session.get_ledger_path()
            if path then
                print("current ledger:", path)
            else
                print("no ledger set")
            end
            goto continue
        end

        --------------------------------------------------------
        -- Delegate to CLI
        --------------------------------------------------------

        local argv = tokenize("ledger " .. input)

        local ok, err = pcall(function()
            CLI.run(argv)
        end)

        if not ok then
            print("error:", err)
        end

        ::continue::
    end
end

return M
