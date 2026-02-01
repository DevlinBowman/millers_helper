#!/usr/bin/env lua
-- app/run.lua
--
-- Minimal CLI runner.
-- Kept separate from main.lua (build / scratch entrypoint).

local CLI = require("cli")

local ok, err = pcall(CLI.run, { ... })
if not ok then
    io.stderr:write("error: " .. tostring(err) .. "\n")
    os.exit(1)
end
