-- system/execution/target_resolver.lua

local Resolver = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function require_batch(envelope, label)

    assert(type(envelope) == "table",
        "[execution] "..label.." envelope required")

    assert(type(envelope.batch) == "function",
        "[execution] "..label.." envelope missing batch()")

    local batch = envelope:batch()

    assert(type(batch) == "table",
        "[execution] "..label.." batch required")

    return batch
end


local function normalize_selector(selector)

    if selector == nil then
        return {}
    end

    if type(selector) == "number" then
        return { batch = selector }
    end

    if type(selector) == "table" then
        return selector
    end

    error("[execution] invalid selector")
end


local function resolve_batch_index(batches, requested)

    local count = #batches

    if count == 0 then
        return nil
    end

    -- nil → first
    if requested == nil then
        return 1
    end

    -- out of range → last
    if requested > count then
        return count
    end

    if requested < 1 then
        return 1
    end

    return requested
end


local function wrap_batch(envelope, batch)

    return setmetatable({},{
        __index = function(_, k)
            if k == "batch" then
                return function() return batch end
            end
            return envelope[k]
        end
    })
end


------------------------------------------------------------
-- Job Resolution
------------------------------------------------------------

function Resolver.resolve_job(runtime, resource_selector, selection)

    local base =
        runtime:require("user", "job", resource_selector)

    local batches =
        base.__batches

    assert(type(batches) == "table",
        "[execution] job envelope missing batches")

    local selector =
        normalize_selector(selection)

    local batch_index =
        resolve_batch_index(batches, selector.batch)

    local batch =
        batches[batch_index]

    assert(type(batch) == "table",
        "[execution] job batch resolution failed")

    local env =
        wrap_batch(base, batch)

    ------------------------------------------------
    -- optional board targeting
    ------------------------------------------------

    if selector.board then

        local boards =
            batch.boards or {}

        local board =
            boards[selector.board]

        if board then
            return env, { boards = { board } }, { batch = batch_index, board = selector.board }
        end
    end

    return env, batch, { batch = batch_index }
end


------------------------------------------------------------
-- Vendor Resolution
------------------------------------------------------------

function Resolver.resolve_vendors(runtime, selection)

    local batches =
        runtime:batches("system","vendor")

    assert(type(batches) == "table",
        "[execution] vendor batches required")

    local selector =
        normalize_selector(selection)

    if selector.batch then

        local batch_index =
            resolve_batch_index(batches, selector.batch)

        local batch =
            batches[batch_index]

        return nil, { batch }, { batch = batch_index }
    end

    return nil, batches, { batch = "all" }
end


return Resolver
