-- pipelines/context_bundle.lua
--
-- Multi-source bundle assembler.
-- Responsibility:
--   • Load order file via pipelines.ingest.read
--   • Load boards file via pipelines.ingest.read
--   • Return built objects (order + boards) + provenance meta
--
-- NOTE:
--   pipelines.ingest.read returns:
--     { order = <Order>, boards = <Board[]>, meta = { io = ... } }

local Ingest   = require("pipelines.ingest")
local Trace    = require("tools.trace")
local Contract = require("core.contract")

local Bundle = {}

----------------------------------------------------------------
-- Contract
----------------------------------------------------------------

Bundle.CONTRACT = {
    load = {
        in_ = {
            order_path  = true,
            boards_path = true,
            opts        = false,
        },
        out = {
            order  = true, -- built Order
            boards = true, -- built Board[]
            meta   = true, -- provenance only
        },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param order_path string
---@param boards_path string
---@param opts table|nil
---@return table|nil result
---@return string|nil err
function Bundle.load(order_path, boards_path, opts)
    Trace.contract_enter("pipelines.context_bundle.load")
    Trace.contract_in(Bundle.CONTRACT.load.in_)

    Contract.assert(
        { order_path = order_path, boards_path = boards_path, opts = opts },
        Bundle.CONTRACT.load.in_
    )

    assert(type(order_path) == "string", "Bundle.load(): order_path string required")
    assert(type(boards_path) == "string", "Bundle.load(): boards_path string required")
    opts = opts or {}

    ------------------------------------------------------------
    -- Load Order (built objects)
    ------------------------------------------------------------
    local order_result, order_err = Ingest.read(order_path, opts)
    if not order_result then
        Trace.contract_leave()
        return nil, order_err
    end

    ------------------------------------------------------------
    -- Load Boards (built objects)
    ------------------------------------------------------------
    local boards_result, boards_err = Ingest.read(boards_path, opts)
    if not boards_result then
        Trace.contract_leave()
        return nil, boards_err
    end

    ------------------------------------------------------------
    -- Validate expectations
    ------------------------------------------------------------
    if type(boards_result.boards) ~= "table" or #boards_result.boards == 0 then
        Trace.contract_leave()
        return nil, "no boards found in boards file"
    end

    ------------------------------------------------------------
    -- Merge (objects only)
    ------------------------------------------------------------
    local out = {
        order  = order_result.order,
        boards = boards_result.boards,
        meta   = {
            order_source  = order_result.meta,
            boards_source = boards_result.meta,
        },
    }

    Trace.contract_out(Bundle.CONTRACT.load.out, "pipelines.context_bundle", "caller")
    Contract.assert(out, Bundle.CONTRACT.load.out)
    Trace.contract_leave()

    return out
end

return Bundle
