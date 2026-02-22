-- system/app/runtime_hub.lua
--
-- RuntimeHub
-- ==========
--
-- RuntimeHub is the system's runtime composition layer.
--
-- It sits between:
--   • Persisted resource specifications (State.resources)
--   • Domain runtime construction (core.domain.runtime.controller)
--
-- Responsibilities:
--   • Hold persisted resource specs (shared reference)
--   • Lazily construct runtime objects
--   • Support simple and labeled input composition
--   • Cache constructed runtimes (ephemeral)
--
-- It explicitly does NOT:
--   • Perform domain logic
--   • Persist anything
--   • Access filesystem directly
--   • Know about services or UI
--
-- Lifecycle:
--   Surface → RuntimeHub.new(state.resources)
--   Service → hub:require("user")
--   Hub     → RuntimeController.load(...)
--
-- Design invariant:
--   _specs is a shared table reference to State.resources.
--   Mutating specs affects runtime resolution immediately.

local RuntimeController = require("core.domain.runtime.controller")

---@class RuntimeHub
---@field _specs table<string, { inputs: table, opts: table }>
---@field _cache table<string, any>  -- ephemeral runtime cache
local RuntimeHub = {}
RuntimeHub.__index = RuntimeHub

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

---@param initial_specs? table
---@return RuntimeHub
function RuntimeHub.new(initial_specs)
    local self = setmetatable({}, RuntimeHub)

    -- Shared reference to persisted resource specifications.
    -- DO NOT clone.
    self._specs = initial_specs or {}

    -- Runtime objects are cached here.
    -- Never persisted.
    self._cache = {}

    return self
end

----------------------------------------------------------------
-- Spec Management (Persisted)
----------------------------------------------------------------
-- These methods mutate the spec layer.
-- They do NOT load runtimes.
-- Any change invalidates the cache for that name.

---@param name string
---@param inputs table
---@param opts? table
---@return boolean|string
function RuntimeHub:set(name, inputs, opts)
    if type(name) ~= "string" or name == "" then
        return false, "invalid name"
    end

    if type(inputs) ~= "table" then
        return false, "resource inputs must be table"
    end

    self._specs[name] = {
        inputs = inputs,
        opts   = opts or {}
    }

    -- Invalidate runtime cache
    self._cache[name] = nil

    return true
end

---@param name string
function RuntimeHub:clear(name)
    self._specs[name] = nil
    self._cache[name] = nil
end

---@param name string
---@return table|nil
function RuntimeHub:spec(name)
    return self._specs[name]
end

---@return table
function RuntimeHub:specs()
    return self._specs
end

----------------------------------------------------------------
-- Internal Helpers
----------------------------------------------------------------

---@param inputs table
---@return boolean
local function is_labeled_inputs(inputs)
    return type(inputs) == "table"
        and (inputs.orders ~= nil or inputs.boards ~= nil)
end

----------------------------------------------------------------
-- Loading
----------------------------------------------------------------
-- Runtime construction happens here.
--
-- Failure model:
--   • Returns nil, err on invalid spec
--   • Does NOT throw

---@param name string
---@return any|nil runtime
---@return string|nil err
function RuntimeHub:load(name)

    local spec = self._specs[name]
    if not spec then
        return nil, "missing spec: " .. tostring(name)
    end

    local inputs = spec.inputs
    local opts   = spec.opts or {}

    if type(inputs) ~= "table" then
        return nil, "resource inputs must be table"
    end

    ------------------------------------------------------------
    -- CASE 1: Simple input (no labels)
    --
    -- Example:
    --   { "file1.csv", "file2.csv" }
    ------------------------------------------------------------

    if not is_labeled_inputs(inputs) then

        local runtime

        if #inputs == 1 then
            -- Single input unwrap
            runtime = RuntimeController.load(inputs[1], opts)
        else
            -- Multiple inputs → merge batches
            local merged_batches = {}

            for _, input_value in ipairs(inputs) do
                local r = RuntimeController.load(input_value, opts)

                for _, batch in ipairs(r:batches()) do
                    merged_batches[#merged_batches + 1] = batch
                end
            end

            -- Lightweight runtime wrapper
            runtime = {
                batches = function() return merged_batches end
            }
        end

        self._cache[name] = runtime
        return runtime
    end

    ------------------------------------------------------------
    -- CASE 2: Labeled input (orders + boards)
    --
    -- Example:
    -- {
    --   orders = ...,
    --   boards = ...
    -- }
    ------------------------------------------------------------

    local order_inputs = inputs.orders
    local board_inputs = inputs.boards

    if not order_inputs then
        return nil, "labeled resource missing 'orders'"
    end

    if not board_inputs then
        return nil, "labeled resource missing 'boards'"
    end

    local order_runtime =
        RuntimeController.load(order_inputs, {
            category = "order",
            name     = name
        })

    local board_runtime =
        RuntimeController.load(board_inputs, {
            category = "board",
            name     = name
        })

    local associated =
        RuntimeController.associate(
            order_runtime,
            board_runtime,
            { name = name }
        )

    self._cache[name] = associated

    return associated
end

----------------------------------------------------------------
-- Access (Lazy + Safe)
----------------------------------------------------------------
-- get():
--   • Returns cached runtime if present
--   • Otherwise triggers load()
--
-- require():
--   • Same as get()
--   • Explicit failure propagation

---@param name string
---@return any|nil runtime
---@return string|nil err
function RuntimeHub:get(name)
    if self._cache[name] then
        return self._cache[name]
    end
    return self:load(name)
end

---@param name string
---@return any|nil runtime
---@return string|nil err
function RuntimeHub:require(name)
    local runtime, err = self:get(name)
    if not runtime then
        return nil, err
    end
    return runtime
end

----------------------------------------------------------------
-- Introspection
----------------------------------------------------------------

---@param name string
---@return boolean
function RuntimeHub:is_loaded(name)
    return self._cache[name] ~= nil
end

---@param name string
---@return boolean
function RuntimeHub:is_configured(name)
    return self._specs[name] ~= nil
end

return RuntimeHub
