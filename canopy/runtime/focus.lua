-- canopy/runtime/focus.lua
--
-- Cursor placement policy.

local Focus = {}

function Focus.first_valid_line(line_map)
    for i = 1, #line_map do
        if line_map[i] then
            return i
        end
    end
    return 1
end

function Focus.restore(surface, line_map, previous_line)
    if previous_line and line_map[previous_line] then
        vim.api.nvim_win_set_cursor(surface.win, { previous_line, 0 })
        return
    end

    local first = Focus.first_valid_line(line_map)
    vim.api.nvim_win_set_cursor(surface.win, { first, 0 })
end

return Focus
