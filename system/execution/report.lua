local Reporter = {}

local function indent(depth)
    return string.rep("  ", depth or 0)
end

local function log(depth, msg)
    print(indent(depth) .. msg)
end

------------------------------------------------
-- Begin Service
------------------------------------------------

function Reporter.begin(ctx, service_name)

    local depth =
        ctx.depth or 0

    log(depth, "[execution] BEGIN")
    log(depth, string.format(
        "[execution] service:  %s",
        tostring(service_name)
    ))

    ------------------------------------------------
    -- pricing reporting
    ------------------------------------------------

    if service_name == "pricing" then

        local vendors =
            ctx.env and ctx.env.vendors or {}

        local selector =
            ctx.resolved and ctx.resolved.vendors

        ------------------------------------------------
        -- vendor selection
        ------------------------------------------------

        if selector and selector.batch and selector.batch ~= "all" then

            log(depth, string.format(
                "[execution] vendor batch: %s",
                tostring(selector.batch)
            ))

        else

            log(depth, string.format(
                "[execution] vendors: %d (all)",
                #vendors
            ))

        end

        ------------------------------------------------
        -- vendor identity
        ------------------------------------------------

        for i, batch in ipairs(vendors) do

            local vendor_id =
                batch and batch.id or "?"

            local board_count =
                batch and batch.boards and #batch.boards or 0

            log(depth, string.format(
                "[execution] vendor[%d]: %s (%d boards)",
                i,
                tostring(vendor_id),
                board_count
            ))

        end

        ------------------------------------------------
        -- job scope
        ------------------------------------------------

        local job_batch =
            ctx.resolved
            and ctx.resolved.job
            and ctx.resolved.job.batch
            or "?"

        log(depth, string.format(
            "[execution] job batch: %s",
            tostring(job_batch)
        ))

        if ctx.target and ctx.target.board_indices then

            log(depth, string.format(
                "[execution] scoped boards: %d",
                #ctx.target.board_indices
            ))

        end

        ------------------------------------------------
        -- strategy
        ------------------------------------------------

        if ctx.strategy then

            log(depth, string.format(
                "[execution] strategy: %s",
                tostring(ctx.strategy)
            ))

        end

        ------------------------------------------------
        -- strategy options
        ------------------------------------------------

        local opts =
            ctx.env and ctx.env.opts or {}

        for k, v in pairs(opts) do

            if type(v) ~= "table" then

                log(depth, string.format(
                    "[execution] opt.%s = %s",
                    tostring(k),
                    tostring(v)
                ))

            end

        end

        return
    end

    ------------------------------------------------
    -- job reporting
    ------------------------------------------------

    local batch =
        (ctx.resolved
        and ctx.resolved.job
        and ctx.resolved.job.batch)
        or "?"

    log(depth, string.format(
        "[execution] target:   job -> batch[%s]",
        tostring(batch)
    ))

    if ctx.target and ctx.target.boards then

        log(depth, string.format(
            "[execution] boards:   %d",
            #ctx.target.boards
        ))

    end

end


------------------------------------------------
-- End Service
------------------------------------------------

function Reporter.finish(ctx)

    local depth =
        ctx.depth or 0

    log(depth, "[execution] END")

end


------------------------------------------------
-- Mutation Reporting
------------------------------------------------

function Reporter.mutation(ctx, capability)

    local depth =
        ctx.depth or 0

    log(depth, string.format(
        "[execution] mutation applied: %s",
        tostring(capability)
    ))

end

return Reporter
