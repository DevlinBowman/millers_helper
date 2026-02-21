-- canopy/runtime/app.lua
--
-- Owns runtime lifecycle.

local Renderer    = require("canopy.internal.render")
local Input       = require("canopy.internal.input")
local Focus       = require("canopy.runtime.focus")
local Edit        = require("canopy.runtime.edit")
local Adapter     = require("canopy.runtime.adapter")      -- legacy model->tree
local SpecAdapter = require("canopy.runtime.spec_adapter") -- spec->tree

local App         = {}
App.__index       = App

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

function App.new(opts)
    opts = opts or {}

    local SpecContract = require("canopy.contract")

    if opts.spec then
        SpecContract.validate_spec(opts.spec)
    end

    local self                  = setmetatable({}, App)

    -- Navigation stack
    self.stack                  = {}

    self.mode                   = opts.mode or "embedded"
    self.actions                = opts.actions or {}
    self.context                = opts.context or {}

    -- Inject canopy namespace safely
    self.context.canopy         = self.context.canopy or {}
    self.context.canopy.storage = self.context.canopy.storage or {}

    if opts.storage then
        if opts.storage.path ~= nil then
            self.context.canopy.storage.path = opts.storage.path
        end
        if type(opts.storage.set_path) == "function" then
            self.context.canopy.storage.set_path = opts.storage.set_path
        end
        if type(opts.storage.save) == "function" then
            self.context.canopy.storage.save = opts.storage.save
        end
    end

    self.line_map    = {}
    self.last_cursor = nil
    local Surface

    if vim then
        Surface = require("canopy.surfaces.nvim")
    else
        error("Canopy requires Neovim surface when running UI mode")
    end

    self.surface = Surface.new(self.mode)

    ------------------------------------------------------------
    -- Spec-first mode
    ------------------------------------------------------------
    if opts.spec then
        self.current_spec = opts.spec
        self.title        = (opts.spec.title or opts.title or "Canopy")

        local adapted     = SpecAdapter.to_tree(self.current_spec, self.context)
        self.tree         = adapted.tree

        self.root_title   = self.title
        self.root_tree    = self.tree
    else
        --------------------------------------------------------
        -- Legacy model/tree mode
        --------------------------------------------------------
        self.title = opts.title or "Canopy"

        if opts.model then
            self.model = opts.model
            self.original_model = vim.deepcopy(opts.model)
            self.tree = Adapter.from_model(opts.model)
        else
            self.tree = opts.tree or {}
            self.model = nil
            self.original_model = nil
        end

        self.root_tree  = self.tree
        self.root_title = self.title
    end

    self._dirty = false

    return self
end

------------------------------------------------------------
-- Public helpers
------------------------------------------------------------

function App:mark_dirty()
    self._dirty = true
end

function App:clear_dirty()
    self._dirty = false
end

------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------

function App:run()
    self.surface:create_window()
    self:_render(true)
    self:_bind_keys()
end

------------------------------------------------------------
-- Rendering
------------------------------------------------------------

function App:_render(initial)
    -- If spec mode, re-adapt on each render (React-like: view derives from spec+ctx)
    if self.current_spec then
        local adapted = SpecAdapter.to_tree(self.current_spec, self.context)
        self.title = adapted.title
        self.tree = adapted.tree
    end

    local result = Renderer.render({
        title = self.title,
        tree = self.tree,
    })

    self.line_map = result.line_map
    self.surface:render(result.lines)

    if initial then
        Focus.restore(self.surface, self.line_map, nil)
    else
        Focus.restore(self.surface, self.line_map, self.last_cursor)
    end
end

------------------------------------------------------------
-- Navigation stack
------------------------------------------------------------

function App:push_spec(next_spec)
    table.insert(self.stack, {
        spec  = self.current_spec,
        title = self.title,
        tree  = self.tree,
    })

    self.current_spec = next_spec
    self.last_cursor = nil
    self:_render(true)

    if self.current_spec and type(self.current_spec.on_enter) == "function" then
        pcall(self.current_spec.on_enter, self.context)
    end
end

function App:pop_spec()
    if #self.stack == 0 then
        return false
    end

    local prev = table.remove(self.stack)
    self.current_spec = prev.spec
    self.title = prev.title
    self.tree = prev.tree

    self.last_cursor = nil
    self:_render(true)
    return true
end

------------------------------------------------------------
-- Exit / Save integration
------------------------------------------------------------

function App:_handle_exit()
    -- If dirty and storage.save exists, open save flow
    local storage = (self.context.canopy or {}).storage or {}
    if self._dirty and type(storage.save) == "function" then
        -- Delegate to app-defined save behavior (can show diff/modal via your spec)
        local ok, err = pcall(storage.save, self.context)
        if not ok then
            print("Save failed:", err)
        end
        return
    end

    self.surface:close()
end

------------------------------------------------------------
-- Spec node handling
------------------------------------------------------------

function App:_handle_spec_enter(node)
    local spec_node = node.__spec
    if not spec_node then
        return
    end

    -- 1) Static children -> push a derived spec
    if spec_node.children then
        self:push_spec({
            id = (self.current_spec and self.current_spec.id or "spec") .. ":" .. tostring(spec_node.id or "children"),
            title = spec_node.label or "Options",
            nodes = spec_node.children,
        })
        return
    end

    -- 2) resolve(ctx) -> push resolved spec/nodes
    if type(spec_node.resolve) == "function" then
        local ok, result = pcall(spec_node.resolve, self.context)
        if not ok then
            print("resolve() failed:", result)
            return
        end
        local resolved_spec = SpecAdapter.normalize_resolve(result)
        self:push_spec(resolved_spec)
        return
    end

    -- 3) next(ctx) -> push next spec
    if type(spec_node.next) == "function" then
        local ok, next_spec = pcall(spec_node.next, self.context)
        if not ok then
            print("next() failed:", next_spec)
            return
        end
        if type(next_spec) == "table" then
            self:push_spec(next_spec)
        end
        return
    end

    -- 4) action(ctx)
    if type(spec_node.action) == "function" then
        local ok, err = pcall(spec_node.action, self.context)
        if not ok then
            print("action() failed:", err)
        end
        self:_render(false)
        return
    end
end

------------------------------------------------------------
-- Key bindings
------------------------------------------------------------

-- canopy/runtime/app.lua

function App:_bind_keys()
    self.surface:set_keymaps({
        enter = function()
            local line = self.surface:get_cursor_line()
            self.last_cursor = line

            local node = self.line_map[line]

            -- Spec mode: interpret declaratively
            if self.current_spec and node and node.__spec then
                if node.editable then
                    Edit.start(self, node)
                    return
                end
                self:_handle_spec_enter(node)
                return
            end

            -- Legacy mode behavior
            if node and node.editable then
                Edit.start(self, node)
                return
            end

            local action = Input.handle_enter({
                tree = self.tree,
                actions = self.actions,
                context = self.context,
            }, node)

            if action == "rerender" then
                self:_render(false)
            end
        end,

        quit = function()
            -- Spec stack pop first
            if self.current_spec then
                if self:pop_spec() then
                    return
                end
                self:_handle_exit()
                return
            end

            self:_handle_exit()
        end,

        collapse = function()
            -- Toggle collapse all visible nodes
            local any_expanded = false
            for _, node in ipairs(self.tree or {}) do
                if (node.children or node.__has_children) and not node.collapsed then
                    any_expanded = true
                    break
                end
            end

            local target_collapsed = any_expanded and true or false

            for _, node in ipairs(self.tree or {}) do
                if node.children or node.__has_children then
                    node.collapsed = target_collapsed
                    if node.__spec and type(node.__spec) == "table" then
                        node.__spec.collapsed = target_collapsed
                    end
                end
            end

            self:_render(false)
        end,
    })
end

------------------------------------------------------------
-- Tree reset (legacy)
------------------------------------------------------------

function App:set_tree(_, opts)
    opts = opts or {}

    -- Spec mode: allow replacing current spec
    if opts.spec then
        self.current_spec = opts.spec
        self.stack = {}
        self.last_cursor = nil
        self:_render(true)
        self:clear_dirty()
        return
    end

    -- Legacy model/tree
    if opts.model then
        self.model = opts.model
        self.original_model = vim.deepcopy(opts.model)
        self.tree = Adapter.from_model(opts.model)
        self.root_tree = self.tree
    else
        self.tree = opts.tree or {}
        self.root_tree = self.tree
    end

    self.stack = {}
    self.last_cursor = nil
    self:clear_dirty()

    self:_render(true)
end

return App
