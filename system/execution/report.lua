-- system/execution/report.lua

local Reporter = {}

local function indent(depth)
    return string.rep("  ", depth or 0)
end

local function log(depth, message)
    print(indent(depth) .. message)
end

local function log_job_scope(depth, ctx)
    local job_batch =
        ctx.resolved
        and ctx.resolved.job
        and ctx.resolved.job.batch
        or "?"

    log(depth, string.format(
        "[execution] job batch: %s",
        tostring(job_batch)
    ))

    if ctx.target and type(ctx.target.board_indices) == "table" then
        log(depth, string.format(
            "[execution] scoped boards: %d",
            #ctx.target.board_indices
        ))
    end
end

local function log_vendor_scope(depth, ctx)
    local vendors =
        ctx.env and ctx.env.vendors or {}

    local vendor_meta =
        ctx.resolved and ctx.resolved.vendors or {}

    if vendor_meta.batch ~= nil and vendor_meta.batch ~= "all" then
        log(depth, string.format(
            "[execution] vendor batch: %s",
            tostring(vendor_meta.batch)
        ))
    else
        log(depth, string.format(
            "[execution] vendors: %d (all)",
            #vendors
        ))
    end

    for index, batch in ipairs(vendors) do
        local vendor_id =
            batch and (batch.id or batch.name) or "?"

        local board_count =
            batch and batch.boards and #batch.boards or 0

        log(depth, string.format(
            "[execution] vendor[%d]: %s (%d boards)",
            index,
            tostring(vendor_id),
            board_count
        ))
    end
end

local function log_strategy(depth, ctx)
    if type(ctx.strategy) == "string" and ctx.strategy ~= "" then
        log(depth, string.format(
            "[execution] strategy: %s",
            tostring(ctx.strategy)
        ))
    end
end

local function log_scalar_opts(depth, ctx)
    local opts = ctx.env and ctx.env.opts or {}

    for key, value in pairs(opts) do
        if type(value) ~= "table" then
            log(depth, string.format(
                "[execution] opt.%s = %s",
                tostring(key),
                tostring(value)
            ))
        end
    end
end

------------------------------------------------
-- Begin Service
------------------------------------------------

function Reporter.begin(ctx, service_name)
    local depth = ctx.depth or 0

    log(depth, "[execution] BEGIN")
    log(depth, string.format(
        "[execution] service: %s",
        tostring(service_name)
    ))

    log_job_scope(depth, ctx)

    if service_name == "pricing" then
        log_vendor_scope(depth, ctx)
        log_strategy(depth, ctx)
        log_scalar_opts(depth, ctx)
    end
end

------------------------------------------------
-- End Service
------------------------------------------------

function Reporter.finish(ctx, service_name, status)
    local depth = ctx.depth or 0

    log(depth, string.format(
        "[execution] status: %s",
        tostring(status or ctx.status or "unknown")
    ))

    if service_name then
        log(depth, string.format(
            "[execution] complete: %s",
            tostring(service_name)
        ))
    end

    log(depth, "[execution] END")
end

------------------------------------------------
-- Mutation Reporting
------------------------------------------------

function Reporter.mutation(ctx, capability)
    local depth = ctx.depth or 0

    log(depth, string.format(
        "[execution] mutation applied: %s",
        tostring(capability)
    ))
end

return Reporter
