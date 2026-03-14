-- system/execution/context/resolver.lua

local Resolver = {}

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function resolve_batch_index(batches, requested)

    local count = #batches

    if count == 0 then
        return nil
    end

    if requested == nil then
        return 1
    end

    if requested > count then
        return count
    end

    if requested < 1 then
        return 1
    end

    return requested
end

------------------------------------------------------------
-- resolve
------------------------------------------------------------

function Resolver.resolve(app, service, opts)

    opts = opts or {}

    local data    = app:data()
    local runtime = data:runtime()
    local slots   = data:slots()

    ------------------------------------------------
    -- job selector
    ------------------------------------------------

    local job_sel =
        opts.job_selector
        or slots:get_selection("user", "job:" .. service)
        or slots:get_selection("user", "job")
        or {}

    ------------------------------------------------
    -- vendor selector
    ------------------------------------------------

    local vendor_sel =
        opts.vendor_selector
        or slots:get_selection("system", "vendor:" .. service)
        or slots:get_selection("system", "vendor")
        or {}

    ------------------------------------------------
    -- job envelope
    ------------------------------------------------

    local job_env =
        runtime:require("user", "job")

    local job_batches =
        job_env.__batches

    assert(type(job_batches) == "table",
        "[execution] job batches missing")

    local job_batch_index =
        resolve_batch_index(job_batches, job_sel.batch)

    local job_batch =
        job_batches[job_batch_index]

    assert(type(job_batch) == "table",
        "[execution] job batch resolution failed")

    ------------------------------------------------
    -- board scope
    ------------------------------------------------

    local boards =
        job_batch.boards or {}

    local board_indices = {}

    if job_sel.board then

        if boards[job_sel.board] then
            board_indices = { job_sel.board }
        end

    else

        for i = 1, #boards do
            board_indices[#board_indices + 1] = i
        end

    end

    local scoped_boards = {}

    for _, idx in ipairs(board_indices) do

        local board =
            boards[idx]

        if board then
            scoped_boards[#scoped_boards + 1] = board
        end

    end

    ------------------------------------------------
    -- vendor envelope
    ------------------------------------------------

    local vendor_env =
        runtime:require("system", "vendor")

    local vendor_batches =
        runtime:batches("system", "vendor")

    assert(type(vendor_batches) == "table",
        "[execution] vendor batches required")

    ------------------------------------------------
    -- vendor batch selection
    ------------------------------------------------

    if vendor_sel.batch then

        local vendor_index =
            resolve_batch_index(vendor_batches, vendor_sel.batch)

        vendor_batches =
            { vendor_batches[vendor_index] }

    end

    ------------------------------------------------
    -- return context
    ------------------------------------------------

    return {

        job_env    = job_env,
        vendor_env = vendor_env,

        job_target = {
            batch         = job_batch,
            boards        = scoped_boards,
            board_indices = board_indices,
            all_boards    = boards
        },

        vendor_batches = vendor_batches,

        resolved = {
            job = {
                batch = job_batch_index
            },

            vendors = {
                batch = vendor_sel.batch or "all"
            }
        }
    }
end

return Resolver
