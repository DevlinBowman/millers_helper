-- pipelines/context_bundle.lua
--
-- Multi-source bundle assembler.
--
-- Responsibility:
--   • Load order file via pipelines.ingest.read
--   • Load boards file via pipelines.ingest.read
--   • Extract aggregated order + boards
--   • Merge into single structural bundle
--
-- NOTE:
--   pipelines.ingest.read returns:
--     {
--       codec = "orders",
--       data  = { { order=table, boards=table[] }[] },
--       meta  = ...
--     }

local Ingest    = require("pipelines.ingestion.ingest")
local Trace     = require("tools.trace.trace")
local Contract  = require("core.contract")

local Bundle    = {}

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
            codec = true,
            data  = true,
            meta  = true,
        },
    },
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

-- pipelines/context_bundle.lua
-- function extract_single_order

local function extract_single_order(result)
    assert(result.codec == "lua_object",
        "expected ingest codec 'lua_object'")

    if type(result.data) ~= "table" or #result.data == 0 then
        return nil, "no orders found"
    end

    if #result.data > 1 then
        return nil,
            "order file contains multiple order groups; expected exactly one"
    end

    local batch = result.data[1]

    if not batch.order then
        return nil, "order batch missing order object"
    end

    return batch.order
end

-- pipelines/context_bundle.lua
-- function extract_all_boards

local function extract_all_boards(result)
    assert(result.codec == "lua_object",
        "expected ingest codec 'lua_object'")

    if type(result.data) ~= "table" or #result.data == 0 then
        return nil, "no data found in boards file"
    end

    local boards = {}

    for _, batch in ipairs(result.data) do
        if type(batch.boards) == "table" then
            for _, board in ipairs(batch.boards) do
                boards[#boards + 1] = board
            end
        end
    end

    if #boards == 0 then
        return nil, "no boards found in boards file"
    end

    return boards
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

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
    -- Load Order File
    ------------------------------------------------------------
    local order_result, order_err = Ingest.read(order_path, opts)
    if not order_result then
        Trace.contract_leave()
        return nil, order_err
    end

    local order, order_extract_err = extract_single_order(order_result)
    if not order then
        Trace.contract_leave()
        return nil, order_extract_err
    end

    ------------------------------------------------------------
    -- Load Boards File
    ------------------------------------------------------------
    local boards_result, boards_err = Ingest.read(boards_path, opts)
    if not boards_result then
        Trace.contract_leave()
        return nil, boards_err
    end

    local boards, boards_extract_err = extract_all_boards(boards_result)
    if not boards then
        Trace.contract_leave()
        return nil, boards_extract_err
    end

    ------------------------------------------------------------
    -- Output Bundle
    ------------------------------------------------------------
    local out = {
        codec = "lua_object",
        data  = {
            {
                order  = order,
                boards = boards,
            }
        },
        meta  = {
            bundle        = true,
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
