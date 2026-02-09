-- interface/shells/tui/widgets/list.lua
--
-- Simple numbered selection list.

local List = {}

function List.select(title, items)
    io.stderr:write("[TUI] List.select: " .. tostring(title) .. "\n")
    io.stderr:write("[TUI] item count: " .. tostring(items and #items or 0) .. "\n")
    io.stderr:flush()

    if not items or #items == 0 then
        return nil
    end

    io.stdout:write("\n")
    io.stdout:write(tostring(title) .. "\n")
    io.stdout:flush()

    for i, item in ipairs(items) do
        io.stdout:write(string.format("  %d) %s\n", i, tostring(item)))
    end

    io.stdout:write("\nSelect (number, empty to cancel): ")
    io.stdout:flush()

    io.stderr:write("[TUI] waiting for user input...\n")
    io.stderr:flush()

    local input = io.read("*l")
    if not input or input == "" then
        return nil
    end

    local idx = tonumber(input)
    if not idx or idx < 1 or idx > #items then
        io.stderr:write("[TUI] invalid selection: " .. tostring(input) .. "\n")
        io.stderr:flush()
        return nil
    end

    return items[idx]
end

return List
