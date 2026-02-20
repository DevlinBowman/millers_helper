-- canopy/internal/surfaces/nvim.lua

if not vim then
    error("Canopy nvim surface requires Neovim")
end

local Surface = {}
Surface.__index = Surface

function Surface.new(mode)
    return setmetatable({
        mode = mode or "embedded",
        buf = nil,
        win = nil,
        previous_ui_state = nil,
    }, Surface)
end

----------------------------------------------------------------
-- Save current UI settings (for app mode restore)
----------------------------------------------------------------
function Surface:_capture_ui_state()
    return {
        number = vim.wo.number,
        relativenumber = vim.wo.relativenumber,
        signcolumn = vim.wo.signcolumn,
        statusline = vim.o.laststatus,
        showmode = vim.o.showmode,
        cmdheight = vim.o.cmdheight,
    }
end

function Surface:_apply_app_ui()
    vim.o.laststatus = 0
    vim.o.showmode = false
    vim.o.cmdheight = 0

    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
end

function Surface:_restore_ui()
    if not self.previous_ui_state then return end

    vim.o.laststatus = self.previous_ui_state.statusline
    vim.o.showmode = self.previous_ui_state.showmode
    vim.o.cmdheight = self.previous_ui_state.cmdheight

    vim.wo.number = self.previous_ui_state.number
    vim.wo.relativenumber = self.previous_ui_state.relativenumber
    vim.wo.signcolumn = self.previous_ui_state.signcolumn
end

----------------------------------------------------------------
-- Window creation
----------------------------------------------------------------
function Surface:create_window()
    if self.mode == "app" then
        self.previous_ui_state = self:_capture_ui_state()

        vim.cmd("enew")
        self.buf = vim.api.nvim_get_current_buf()
        self.win = vim.api.nvim_get_current_win()

        vim.api.nvim_buf_set_option(self.buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(self.buf, "modifiable", false)

        self:_apply_app_ui()
    else
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

        local win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.7),
            row = math.floor(vim.o.lines * 0.15),
            col = math.floor(vim.o.columns * 0.2),
            style = "minimal",
            border = "rounded",
        })

        self.buf = buf
        self.win = win
    end
end

----------------------------------------------------------------
-- Rendering
----------------------------------------------------------------
function Surface:render(lines)
    vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

function Surface:get_cursor_line()
    return vim.api.nvim_win_get_cursor(self.win)[1]
end

function Surface:set_keymaps(callbacks)
    local buf = self.buf

    vim.keymap.set("n", "<CR>", callbacks.enter, { buffer = buf })
    vim.keymap.set("n", "q", callbacks.quit, { buffer = buf })
    vim.keymap.set("n", "<Esc>", callbacks.quit, { buffer = buf })

    if callbacks.collapse then
        vim.keymap.set("n", "z", callbacks.collapse, { buffer = buf })
    end
end

----------------------------------------------------------------
-- Close behavior
----------------------------------------------------------------
function Surface:close()
    if self.mode == "app" then
        self:_restore_ui()
        vim.cmd("qa!")
    else
        if self.win and vim.api.nvim_win_is_valid(self.win) then
            vim.api.nvim_win_close(self.win, true)
        end
    end
end

return Surface
