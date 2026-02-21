-- interface/tui/menu.lua
--
-- Global menu rules:
--  - q quits everywhere
--  - help/? shows menu help
--  - consistent prompt + routing
--  - domains are specs, not controllers

local Quit = require("interface.quit")

local Menu = {}
Menu.__index = Menu

function Menu.new(opts)
    opts = opts or {}
    return setmetatable({
        title = opts.title or "Menu",
        prompt = opts.prompt or "> ",
        help = opts.help or nil,              -- string or function(ctx)->string
        on_line = opts.on_line,               -- function(ctx, line) -> optional return
        ctx = opts.ctx or {},                 -- shared services/context
        redraw = opts.redraw,                 -- optional function(ctx)
    }, Menu)
end

local function default_help()
    return "commands: help, q"
end

function Menu:print_help()
    local h = self.help
    if type(h) == "function" then
        print(h(self.ctx))
    elseif type(h) == "string" then
        print(h)
    else
        print(default_help())
    end
end

function Menu:run()
    print("\n=== " .. tostring(self.title) .. " ===")

    while true do
        if type(self.redraw) == "function" then
            self.redraw(self.ctx)
        end

        io.write(self.prompt)
        local line = io.read()
        if not line then return end

        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line == "" then goto continue end

        if line == "q" or line == "exit" then
            Quit.now(0)
        end

        if line == "help" or line == "?" then
            self:print_help()
            goto continue
        end

        if type(self.on_line) == "function" then
            local out = self.on_line(self.ctx, line)
            if out == "__back" then
                return
            end
        end

        ::continue::
    end
end

return Menu
