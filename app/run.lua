#!/usr/bin/env lua
-- app/run.lua
--
-- Unified application entrypoint.
-- Dispatches into interface layer (CLI / TUI).

local Interface = require("interface")

local raw_argv = { ... }

local use_menu = false
local argv = {}

for i = 1, #raw_argv do
    local a = raw_argv[i]
    if a == "-m" or a == "--menu" then
        use_menu = true
    else
        argv[#argv + 1] = a
    end
end

local mode = use_menu and "tui" or "cli"

local ok, err = pcall(function()
    Interface.run(argv, { mode = mode })
end)

if not ok then
    io.stderr:write("error: " .. tostring(err) .. "\n")
    os.exit(1)
end
