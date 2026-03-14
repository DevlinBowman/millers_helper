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

        if ctx.env and ctx.env.vendors then

            local selector =
                ctx.resolved
                and ctx.resolved.vendors

            if selector
            and selector.batch
            and selector.batch ~= "all" then

                log(depth, string.format(
                    "[execution] vendor batch: %s",
                    tostring(selector.batch)
                ))

            else

                log(depth, string.format(
                    "[execution] vendors: %d (all)",
                    #ctx.env.vendors
                ))

            end
        end

        if ctx.strategy then
            log(depth, string.format(
                "[execution] strategy: %s",
                tostring(ctx.strategy)
            ))
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

function Reporter.mutation(ctx, capability)

    local depth =
        ctx.depth or 0

    print(string.rep("  ", depth) ..
        "[execution] mutation applied: " .. tostring(capability))
end

return Reporter
