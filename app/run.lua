#!/usr/bin/env lua
-- app/run.lua
--
-- Unified application entrypoint.
-- Dispatches into interface layer (CLI / TUI).

local Interface = require("interface")

local argv = { ... }

-- Detect interface mode flags early
local use_menu = false
local filtered = {}

for i = 1, #argv do
    local a = argv[i]
    if a == "-m" or a == "--menu" then
        use_menu = true
    else
        filtered[#filtered + 1] = a
    end
end

-- Inject mode hint (non-invasive)
if use_menu then
    filtered.mode = "tui"
else
    filtered.mode = "cli"
end

local ok, err = pcall(function()
    Interface.run(filtered)
end)

if not ok then
    io.stderr:write("error: " .. tostring(err) .. "\n")
    os.exit(1)
end
