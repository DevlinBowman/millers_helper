-- core/domain/runtime/controller.lua
--
-- Runtime Domain Controller
--
-- This controller:
--   • Resolves canonical RuntimeBatch[]
--   • Enforces boundary contracts
--   • Wraps batches in RuntimeResult façade
--
-- Public API:
--   load(input, opts?)        -> RuntimeResult | nil, err
--   load_strict(input, opts?) -> RuntimeResult (throws)
--   associate(order_rt, board_rt, opts?) -> RuntimeResult

local Trace        = require("tools.trace.trace")
local LoadPipeline = require("core.domain.runtime.pipelines.load")
local Helpers      = require("core.domain.runtime.internal.helpers")

local Result = require("core.domain.runtime.result")

local Controller = {}

----------------------------------------------------------------
-- LOAD ENTRY
----------------------------------------------------------------

--- Loads runtime from input source.
---@param input any
---@param opts table|nil { name?:string, category?:string }
---@return RuntimeResult|nil, string|nil
function Controller.load(input, opts)
    Trace.contract_enter("core.domain.runtime.controller.load")

    local batches, err =
        Helpers.resolve_batches(input, LoadPipeline.run)

    if not batches then
        Trace.contract_leave()
        return nil, err
    end

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

    local runtime = Result.new(batches)

    Trace.contract_leave()

    return runtime
end

----------------------------------------------------------------
-- STRICT LOAD
----------------------------------------------------------------

---@param input any
---@param opts table|nil
---@return RuntimeResult
function Controller.load_strict(input, opts)
    local runtime, err = Controller.load(input, opts)
    assert(runtime, err or "[runtime] load failed")
    return runtime
end

----------------------------------------------------------------
-- ASSOCIATION ENTRY
----------------------------------------------------------------

---@param order_runtime RuntimeResult
---@param board_runtime RuntimeResult
---@param opts table|nil
---@return RuntimeResult
function Controller.associate(order_runtime, board_runtime, opts)
    Trace.contract_enter("core.domain.runtime.controller.associate")

    assert(type(order_runtime) == "table" and order_runtime.batches,
        "[runtime.associate] invalid order runtime")

    assert(type(board_runtime) == "table" and board_runtime.batches,
        "[runtime.associate] invalid board runtime")

    local order_batches = order_runtime:batches()
    local board_batches = board_runtime:batches()

    assert(#order_batches == 1,
        "[associate] expected exactly 1 order batch")

    assert(#board_batches == 1,
        "[associate] expected exactly 1 board batch")

    local order_batch = order_batches[1]
    local board_batch = board_batches[1]

    local merged_boards = {}
    for i = 1, #board_batch.boards do
        merged_boards[i] = board_batch.boards[i]
    end

    local new_batch = {
        order  = order_batch.order,
        boards = merged_boards,
        meta   = {
            name     = opts and opts.name
                      or order_batch.meta and order_batch.meta.name,
            category = opts and opts.category or "order",
            io       = order_batch.meta and order_batch.meta.io
        }
    }

    local runtime = Result.new({ new_batch })

    Trace.contract_leave()

    return runtime
end

----------------------------------------------------------------

return Controller
