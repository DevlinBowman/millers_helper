-- core/domain/runtime/pipelines/associate.lua
--
-- Canonical association pipeline.
-- Strict 1:1 CLI reconstruction.
-- Does NOT mutate inputs.
-- Preserves order provenance.
--

local M = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function copy_table_shallow(src)
    local out = {}
    if not src then return out end
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
end

----------------------------------------------------------------
-- Associate
----------------------------------------------------------------

---@param order_batches table -- RuntimeBatch[]
---@param board_batches table -- RuntimeBatch[]
---@param opts table|nil
---@return table -- RuntimeBatch[]
function M.run(order_batches, board_batches, opts)
    opts = opts or {}

    local strategy = opts.strategy or "attach_all"

    if strategy ~= "attach_all" then
        error("[associate] unsupported strategy: " .. tostring(strategy), 2)
    end

    ------------------------------------------------------------
    -- STRICT 1:1 VALIDATION
    ------------------------------------------------------------

    if #order_batches ~= 1 then
        error("[associate] expected exactly 1 order batch", 2)
    end

    if #board_batches ~= 1 then
        error("[associate] expected exactly 1 board batch", 2)
    end

    local order_batch = order_batches[1]
    local board_batch = board_batches[1]

    assert(type(order_batch.order) == "table",
           "[associate] invalid order batch")

    assert(type(board_batch.boards) == "table",
           "[associate] invalid board batch")

    ------------------------------------------------------------
    -- COPY BOARDS (NO MUTATION)
    ------------------------------------------------------------

    local merged_boards = {}

    for i = 1, #board_batch.boards do
        merged_boards[i] = board_batch.boards[i]
    end

    ------------------------------------------------------------
    -- META MERGE (PRESERVE ORDER PROVENANCE)
    ------------------------------------------------------------

    local new_meta = copy_table_shallow(order_batch.meta)

    -- Override controlled fields only
    if opts.name then
        new_meta.name = opts.name
    end

    if opts.category then
        new_meta.category = opts.category
    else
        new_meta.category = new_meta.category or "order"
    end

    ------------------------------------------------------------
    -- CONSTRUCT NEW CANONICAL BATCH
    ------------------------------------------------------------

    local new_batch = {
        order  = order_batch.order,
        boards = merged_boards,
        meta   = new_meta
    }

    ------------------------------------------------------------
    -- FINAL VALIDATION
    ------------------------------------------------------------

    assert(type(new_batch.order) == "table",
           "[associate] resulting batch missing order")

    assert(type(new_batch.boards) == "table",
           "[associate] resulting batch missing boards")

    return { new_batch }
end

return M
