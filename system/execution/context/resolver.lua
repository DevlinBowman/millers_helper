-- system/execution/context/resolver.lua

local Resolver = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function normalize_selector(selector)

    if selector == nil then
        return {}
    end

    if type(selector) == "number" then
        return { batch = selector }
    end

    if type(selector) == "string" then
        return { resource = selector }
    end

    if type(selector) == "table" then
        return {
            resource = selector.resource,
            batch    = selector.batch,
            board    = selector.board
        }
    end

    error("[execution] invalid selector")
end


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

    ------------------------------------------------
    -- scope resolution
    ------------------------------------------------

    local boards =
        batch.boards or {}

    local board_indices = {}

    if selector.board then

        if boards[selector.board] then
            board_indices = { selector.board }
        end

    else

        for i = 1, #boards do
            board_indices[#board_indices + 1] = i
        end

    end

    ------------------------------------------------
    -- scoped board view
    ------------------------------------------------

    local scoped_boards = {}

    for _, idx in ipairs(board_indices) do

        local board =
            boards[idx]

        if board then
            scoped_boards[#scoped_boards + 1] = board
        end

    end

    ------------------------------------------------
    -- target structure
    ------------------------------------------------

    local target = {

        batch         = batch,
        boards        = scoped_boards,
        board_indices = board_indices,
        all_boards    = boards

    }

    ------------------------------------------------
    -- envelope passthrough
    ------------------------------------------------

    local env =
        base

    return env, target, { board_indices = board_indices }, { batch = batch_index }

end


------------------------------------------------------------
-- Vendor Resolution
------------------------------------------------------------

function Resolver.resolve_vendors(runtime, selection)

    local batches =
        runtime:batches("system", "vendor")

    assert(type(batches) == "table",
        "[execution] vendor batches required")

    local selector =
        normalize_selector(selection)

    ------------------------------------------------
    -- load vendor envelope (always required)
    ------------------------------------------------

    local vendor_env =
        runtime:require("system", "vendor")

    ------------------------------------------------
    -- specific batch selection
    ------------------------------------------------

    if selector.batch then

        local batch_index =
            resolve_batch_index(batches, selector.batch)

        local batch =
            batches[batch_index]

        if not batch then
            return vendor_env, {}, { batch = nil }
        end

        return vendor_env, { batch }, { batch = batch_index }

    end

    ------------------------------------------------
    -- default → all vendors
    ------------------------------------------------

    return vendor_env, batches, { batch = "all" }
end

return Resolver
