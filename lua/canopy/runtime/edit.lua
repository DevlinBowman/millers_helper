-- canopy/runtime/edit.lua
--
-- Bottom-aligned popup editor.
-- Starts in NORMAL mode.
-- <CR> commits
-- <Esc> in normal cancels
-- <Esc> in insert returns to normal

local Edit = {}

local function create_edit_window(initial_value)
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { initial_value })

    local width = math.max(40, #initial_value + 4)
    local height = 1

    local row = vim.o.lines - 4   -- near bottom
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    -- Move cursor to end of line (normal mode)
    vim.api.nvim_win_set_cursor(win, { 1, #initial_value })

    return buf, win
end

function Edit.start(app, node)
    if not node or not node.editable then return end

    local initial = tostring(node.value or "")
    local buf, win = create_edit_window(initial)

    -- Commit (normal mode)
    vim.keymap.set("n", "<CR>", function()
        Edit.commit(app, node, buf, win)
    end, { buffer = buf })

    -- Commit (insert mode)
    vim.keymap.set("i", "<CR>", function()
        vim.cmd("stopinsert")
        Edit.commit(app, node, buf, win)
    end, { buffer = buf })

    -- Cancel (normal)
    vim.keymap.set("n", "<Esc>", function()
        Edit.cancel(buf, win)
    end, { buffer = buf })

    -- Insert Esc → normal mode
    vim.keymap.set("i", "<Esc>", function()
        vim.cmd("stopinsert")
    end, { buffer = buf })
end

function Edit.commit(app, node, buf, win)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local new_value_raw = table.concat(lines, "\n")

    -- Preserve basic types when possible
    local current_value = node.value
    local new_value = new_value_raw

    if type(current_value) == "number" then
        new_value = tonumber(new_value_raw) or current_value
    elseif type(current_value) == "boolean" then
        new_value = (new_value_raw == "true")
    end

    -- Update rendered node
    node.value = new_value

    -- Spec-driven setter (preferred)
    if node.__edit_set and type(node.__edit_set) == "function" then
        local ok_set, err = pcall(node.__edit_set, new_value)
        if not ok_set then
            print("Edit set() failed:", err)
        else
            if app and app.mark_dirty then
                app:mark_dirty()
            end
        end
    else
        -- Legacy fallback: model path mutation (if present)
        if app.model and node.__path then
            local target = app.model
            for i = 1, #node.__path - 1 do
                target = target[node.__path[i]]
                if not target then break end
            end
            if target then
                target[node.__path[#node.__path]] = new_value
                if app and app.mark_dirty then
                    app:mark_dirty()
                end
            end
        end
    end

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end

    app:_render(false)
    app:_bind_keys()
end


function Edit.cancel(buf, win)
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
end

return Edit

