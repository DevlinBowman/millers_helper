-- canopy/cli.lua
--
-- Config editor CLI entrypoint.

local Canopy = require("canopy")
local Config = require("canopy.runtime.config")

------------------------------------------------------------
-- Parse CLI args
------------------------------------------------------------

local argv = vim.fn.argv()

if #argv == 0 then
    print("Usage: canopy <config.lua>")
    return
end

local path = argv[1]

------------------------------------------------------------
-- Load config model
------------------------------------------------------------

local ok, model_or_err = pcall(Config.load, path)
if not ok then
    print("Failed to load config:")
    print(model_or_err)
    return
end

local model = model_or_err

------------------------------------------------------------
-- Launch editor
------------------------------------------------------------

local app

app = Canopy.open({
    mode = "app",
    title = "Config Editor — " .. path,
    model = model,

    actions = {

        ----------------------------------------------------
        -- Save file (with diff confirmation)
        ----------------------------------------------------
        save = function()
            local Diff   = require("canopy.runtime.diff")
            local Config = require("canopy.runtime.config")

            local changes = Diff.compute(app.original_model, model)

            if #changes == 0 then
                print("No changes to save.")
                return
            end

            ------------------------------------------------
            -- Build diff window content
            ------------------------------------------------
            local lines = {
                "Exiting Editor - To continue please select:",
                "[c] Confirm & save | [b] back | [d] discard | [q] quit without saving",
                string.rep("─", 80),
                "",
                "Detected Changes:",
                "",
            }

            for _, change in ipairs(changes) do
                table.insert(lines, change.path)
                table.insert(lines, "  - old: " .. tostring(change.old))
                table.insert(lines, "  + new: " .. tostring(change.new))
                table.insert(lines, "")
            end

            ------------------------------------------------
            -- Create popup window
            ------------------------------------------------
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
            vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
            vim.api.nvim_buf_set_option(buf, "modifiable", true)

            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(buf, "modifiable", false)

            local width  = math.min(100, vim.o.columns - 6)
            local height = math.min(vim.o.lines - 6, #lines + 2)

            local win = vim.api.nvim_open_win(buf, true, {
                relative = "editor",
                width    = width,
                height   = height,
                row      = math.floor((vim.o.lines - height) / 2),
                col      = math.floor((vim.o.columns - width) / 2),
                style    = "minimal",
                border   = "rounded",
            })

            local function close_popup()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end

            ------------------------------------------------
            -- Confirm & Save
            ------------------------------------------------
            vim.keymap.set("n", "c", function()
                local ok_save, err = pcall(Config.save, path, model)
                if ok_save then
                    app.original_model = vim.deepcopy(model)
                    app._dirty = false
                    print("Saved:", path)
                else
                    print("Save failed:", err)
                end
                close_popup()
            end, { buffer = buf })

            ------------------------------------------------
            -- Back (return to editor)
            ------------------------------------------------
            vim.keymap.set("n", "b", function()
                close_popup()
            end, { buffer = buf })

            ------------------------------------------------
            -- Discard changes (restore original)
            ------------------------------------------------
            vim.keymap.set("n", "d", function()
                model = vim.deepcopy(app.original_model)
                app:set_tree(nil, { model = model })
                app._dirty = false
                close_popup()
            end, { buffer = buf })

            ------------------------------------------------
            -- Quit without saving
            ------------------------------------------------
            vim.keymap.set("n", "q", function()
                close_popup()
                app.surface:close()
            end, { buffer = buf })
        end,

        ----------------------------------------------------
        -- Exit editor (clean exit only)
        ----------------------------------------------------
        exit = function()
            app.surface:close()
        end,
    }
})
