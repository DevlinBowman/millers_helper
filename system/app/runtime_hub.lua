-- system/app/runtime_hub.lua
--
-- Master runtime loader + composition layer.
--
-- Responsibilities:
--   • Store persisted runtime specifications
--   • Lazily construct RuntimeView objects
--   • Compose labeled inputs (orders + boards)
--   • Cache runtime objects (non-persisted)
--
-- No CLI.
-- No printing.
-- No services.

local RuntimeController = require("core.domain.runtime.controller")

local RuntimeHub = {}
RuntimeHub.__index = RuntimeHub

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function RuntimeHub.new(initial_specs)
    local self = setmetatable({}, RuntimeHub)

    -- Persisted resource specs (shared with State)
    self._specs = initial_specs or {}

    -- Ephemeral runtime cache
    self._cache = {}

    return self
end

----------------------------------------------------------------
-- Spec Management (Persisted)
----------------------------------------------------------------

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

    self._cache[name] = nil

    return true
end

function RuntimeHub:clear(name)
    self._specs[name] = nil
    self._cache[name] = nil
end

function RuntimeHub:spec(name)
    return self._specs[name]
end

function RuntimeHub:specs()
    return self._specs
end

----------------------------------------------------------------
-- Internal Helpers
----------------------------------------------------------------

local function is_labeled_inputs(inputs)
    return type(inputs) == "table"
        and (inputs.orders ~= nil or inputs.boards ~= nil)
end

----------------------------------------------------------------
-- Loading
----------------------------------------------------------------

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
    ------------------------------------------------------------

    if not is_labeled_inputs(inputs) then

        local runtime

        if #inputs == 1 then
            -- unwrap single input
            runtime = RuntimeController.load(inputs[1], opts)
        else
            -- multiple simple inputs → load and merge batches
            local merged_batches = {}

            for _, input_value in ipairs(inputs) do
                local r = RuntimeController.load(input_value, opts)
                for _, batch in ipairs(r:batches()) do
                    merged_batches[#merged_batches + 1] = batch
                end
            end

            runtime = {
                batches = function() return merged_batches end
            }
        end

        self._cache[name] = runtime
        return runtime
    end

    ------------------------------------------------------------
    -- CASE 2: Labeled input (orders + boards)
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

function RuntimeHub:get(name)
    if self._cache[name] then
        return self._cache[name]
    end
    return self:load(name)
end

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

function RuntimeHub:is_loaded(name)
    return self._cache[name] ~= nil
end

function RuntimeHub:is_configured(name)
    return self._specs[name] ~= nil
end

return RuntimeHub
