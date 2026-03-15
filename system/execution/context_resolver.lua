-- system/execution/context_resolver.lua

local Resolver = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function assert_selector_table(selector, label)
    assert(selector == nil or type(selector) == "table",
        string.format("[execution.resolver] %s selector must be table", label))
end

local function resolve_batch_index(batches, requested, label)
    local count = #batches

    if count == 0 then
        return nil
    end

    if requested == nil then
        return 1
    end

    assert(type(requested) == "number" and requested >= 1 and requested % 1 == 0,
        string.format("[execution.resolver] %s batch selector must be integer >= 1", label))

    assert(requested <= count,
        string.format(
            "[execution.resolver] %s batch selector out of range: %d > %d",
            label,
            requested,
            count
        ))

    return requested
end

local function build_board_scope(boards, board_index)
    local board_indices = {}
    local scoped_boards = {}

    if board_index ~= nil then
        assert(type(board_index) == "number" and board_index >= 1 and board_index % 1 == 0,
            "[execution.resolver] board selector must be integer >= 1")

        assert(boards[board_index] ~= nil,
            string.format("[execution.resolver] board selector out of range: %d", board_index))

        board_indices[1] = board_index
        scoped_boards[1] = boards[board_index]

        return scoped_boards, board_indices
    end

    for i = 1, #boards do
        board_indices[#board_indices + 1] = i
        scoped_boards[#scoped_boards + 1] = boards[i]
    end

    return scoped_boards, board_indices
end

local function require_batches(envelope, label)
    assert(type(envelope) == "table",
        string.format("[execution.resolver] %s envelope required", label))

    local batches = envelope.__batches

    assert(type(batches) == "table",
        string.format("[execution.resolver] %s batches missing", label))

    return batches
end

------------------------------------------------------------
-- Resolve
------------------------------------------------------------

function Resolver.resolve(app, service_name, opts)
    assert(app ~= nil, "[execution.resolver] app required")
    assert(type(service_name) == "string" and service_name ~= "",
        "[execution.resolver] service_name required")

    opts = opts or {}

    local data    = app:data()
    local runtime = data:runtime()
    local slots   = data:slots()

    local job_sel =
        opts.job_selector
        or slots:get_selection("user", "job:" .. service_name)
        or slots:get_selection("user", "job")
        or {}

    local vendor_sel =
        opts.vendor_selector
        or slots:get_selection("system", "vendor:" .. service_name)
        or slots:get_selection("system", "vendor")
        or {}

    assert_selector_table(job_sel, "job")
    assert_selector_table(vendor_sel, "vendor")

    ------------------------------------------------
    -- Job envelope / batch
    ------------------------------------------------

    local job_env     = runtime:require("user", "job")
    local job_batches = require_batches(job_env, "job")

    local job_batch_index = resolve_batch_index(job_batches, job_sel.batch, "job")
    local job_batch       = job_batches[job_batch_index]

    assert(type(job_batch) == "table",
        "[execution.resolver] job batch resolution failed")

    local boards = job_batch.boards or {}
    assert(type(boards) == "table",
        "[execution.resolver] job batch boards must be table")

    local scoped_boards, board_indices =
        build_board_scope(boards, job_sel.board)

    ------------------------------------------------
    -- Vendor envelope / batches
    ------------------------------------------------

    local vendor_env     = runtime:require("system", "vendor")
    local vendor_batches = runtime:batches("system", "vendor")

    assert(type(vendor_batches) == "table",
        "[execution.resolver] vendor batches required")

    if vendor_sel.batch ~= nil then
        local vendor_index =
            resolve_batch_index(vendor_batches, vendor_sel.batch, "vendor")

        vendor_batches = { vendor_batches[vendor_index] }
    end

    ------------------------------------------------
    -- Return context
    ------------------------------------------------

    return {
        job_env    = job_env,
        vendor_env = vendor_env,

        job_target = {
            batch         = job_batch,
            boards        = scoped_boards,
            board_indices = board_indices,
            all_boards    = boards,
        },

        vendor_batches = vendor_batches,

        resolved = {
            job = {
                batch = job_batch_index,
                board = job_sel.board or "all",
            },

            vendors = {
                batch = vendor_sel.batch or "all",
                count = #vendor_batches,
            }
        }
    }
end

return Resolver
