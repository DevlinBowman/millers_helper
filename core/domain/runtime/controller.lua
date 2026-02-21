-- core/domain/runtime/controller.lua

local Trace        = require("tools.trace.trace")
local Contract     = require("core.contract")
local LoadPipeline = require("core.domain.runtime.pipelines.load")
local Helpers      = require("core.domain.runtime.internal.helpers")
local BatchUtil    = require("core.domain.runtime.internal.batch")
local Associate = require("core.domain.runtime.pipelines.associate")

local Controller = {}

----------------------------------------------------------------
-- TYPES
----------------------------------------------------------------

---@class RuntimeBatchMeta
---@field name string|nil
---@field category string|nil

---@class RuntimeBatch
---@field order table
---@field boards table[]
---@field meta RuntimeBatchMeta|nil

---@class RuntimeView
---@field private _batches RuntimeBatch[]
local RuntimeView = {}
RuntimeView.__index = RuntimeView

----------------------------------------------------------------
-- CONSTRUCTOR
----------------------------------------------------------------

---@param batches RuntimeBatch[]
---@return RuntimeView
function RuntimeView.new(batches)
    local self = setmetatable({}, RuntimeView)
    self._batches = batches
    return self
end

----------------------------------------------------------------
-- CORE ACCESS
----------------------------------------------------------------

---@return RuntimeBatch[]
function RuntimeView:batches()
    return self._batches
end

---@param index integer
---@return RuntimeBatch
function RuntimeView:batch(index)
    return BatchUtil.get_batch(self._batches, index)
end

---@return table[]
function RuntimeView:orders()
    local out = {}
    for i = 1, #self._batches do
        out[i] = self._batches[i].order
    end
    return out
end

---@param index integer
---@return table
function RuntimeView:order(index)
    return BatchUtil.get_order(self._batches, index)
end

---@param index integer|nil
---@return table[]
function RuntimeView:boards(index)
    if index then
        return BatchUtil.get_boards(self._batches, index)
    end

    local out = {}
    for i = 1, #self._batches do
        local boards = self._batches[i].boards
        for j = 1, #boards do
            out[#out + 1] = boards[j]
        end
    end
    return out
end

----------------------------------------------------------------
-- FILTER HELPERS
----------------------------------------------------------------

---@param category string
---@return RuntimeBatch[]
function RuntimeView:batches_by_category(category)
    local out = {}
    for i = 1, #self._batches do
        if self._batches[i].meta
        and self._batches[i].meta.category == category then
            out[#out + 1] = self._batches[i]
        end
    end
    return out
end

----------------------------------------------------------------
-- LOAD ENTRY
----------------------------------------------------------------

---@param input any
---@param opts table|nil { name?:string, category?:string }
---@return RuntimeView
---@param input any
---@param opts table|nil { name?:string, category?:string }
---@return RuntimeView
---@param input any
---@param opts table|nil { name?:string, category?:string }
---@return RuntimeView
function Controller.load(input, opts)
    Trace.contract_enter("core.domain.runtime.controller.load")

    local batches = Helpers.resolve_batches(input, LoadPipeline.run)

    -- Merge context metadata (do NOT overwrite existing meta like meta.io)
    if opts then
        for i = 1, #batches do
            local batch = batches[i]
            batch.meta = batch.meta or {}

            if opts.name ~= nil then
                batch.meta.name = opts.name
            end

            if opts.category ~= nil then
                batch.meta.category = opts.category
            end
        end
    end

    local runtime = RuntimeView.new(batches)

    Trace.contract_leave()

    return runtime
end


----------------------------------------------------------------
-- ASSOCIATION ENTRY
----------------------------------------------------------------

---@param order_runtime RuntimeView
---@param board_runtime RuntimeView
---@param opts table|nil
---@return RuntimeView
function Controller.associate(order_runtime, board_runtime, opts)
    Trace.contract_enter("core.domain.runtime.controller.associate")

    assert(type(order_runtime) == "table" and order_runtime.batches,
           "[runtime.associate] invalid order runtime")

    assert(type(board_runtime) == "table" and board_runtime.batches,
           "[runtime.associate] invalid board runtime")

    local order_batches = order_runtime:batches()
    local board_batches = board_runtime:batches()

    ------------------------------------------------------------
    -- Validation: orders must contain order data
    ------------------------------------------------------------

    assert(#order_batches > 0, "[associate] no order batches")

    for _, batch in ipairs(order_batches) do
        assert(type(batch.order) == "table",
               "[associate] order batch missing order table")
    end

    ------------------------------------------------------------
    -- Collect all boards from board_runtime
    ------------------------------------------------------------

    local collected_boards = {}

    for _, batch in ipairs(board_batches) do
        for _, board in ipairs(batch.boards or {}) do
            collected_boards[#collected_boards + 1] = board
        end
    end

    assert(#collected_boards > 0,
           "[associate] no boards found in board runtime")

    ------------------------------------------------------------
    -- Deterministic rule (simple CLI mode):
    -- If exactly 1 order batch, attach all boards to it.
    ------------------------------------------------------------

    if #order_batches ~= 1 then
        error("[associate] multiple order batches not supported in CLI mode", 2)
    end

    local source_batch = order_batches[1]

    local new_batch = {
        order  = source_batch.order,
        boards = collected_boards,
        meta   = {
            -- preserve order provenance
            name     = opts and opts.name     or source_batch.meta and source_batch.meta.name,
            category = "order",
            io       = source_batch.meta and source_batch.meta.io
        }
    }

    ------------------------------------------------------------
    -- Final canonical validation
    ------------------------------------------------------------

    assert(type(new_batch.order) == "table", "[associate] invalid order")
    assert(type(new_batch.boards) == "table", "[associate] invalid boards")

    local runtime = RuntimeView.new({ new_batch })

    Trace.contract_leave()

    return runtime
end

----------------------------------------------------------------

return Controller
