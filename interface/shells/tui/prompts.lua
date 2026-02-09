-- interface/shells/tui/prompts.lua
--
-- Simple blocking prompts for TUI argument collection.

local Prompts = {}

function Prompts.ask(label)
    io.stdout:write(label .. ": ")
    io.stdout:flush()
    return io.read("*l")
end

function Prompts.ask_many(label)
    io.stdout:write(label .. " (space-separated, empty to finish): ")
    io.stdout:flush()

    local line = io.read("*l")
    if not line or line == "" then
        return {}
    end

    local out = {}
    for token in line:gmatch("%S+") do
        out[#out + 1] = token
    end

    return out
end

return Prompts
