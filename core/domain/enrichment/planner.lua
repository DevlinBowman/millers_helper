-- core/domain/enrichment/planner.lua

local Planner = {}

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function path_to_key(path)
    local parts = {}

    for i, part in ipairs(path or {}) do
        parts[i] = tostring(part)
    end

    return table.concat(parts, ".")
end

local function normalize_target_path(request)
    local path = request.path or {}
    local scope = request.scope

    if not scope or path[1] ~= scope then
        return path
    end

    ------------------------------------------------
    -- collection item target
    -- boards -> { "boards", index }
    ------------------------------------------------

    if type(path[2]) == "number" then
        return { path[1], path[2] }
    end

    ------------------------------------------------
    -- container target
    ------------------------------------------------

    return { path[1] }
end

local function should_drop_container_target(targets_by_key, scope)
    for _, target in pairs(targets_by_key) do
        if target.path[1] == scope and type(target.path[2]) == "number" then
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- compile requests into service tasks
------------------------------------------------------------

function Planner.compile(object, requests)
    local groups = {}

    for _, request in ipairs(requests or {}) do
        local group_key = tostring(request.service) .. "::" .. tostring(request.scope or "root")
        local group = groups[group_key]

        if not group then
            group = {
                service  = request.service,
                scope    = request.scope,
                package  = request.package,
                requests = {},
                targets  = {},
                _targets_by_key = {},
            }

            groups[group_key] = group
        end

        group.requests[#group.requests + 1] = request

        local target_path = normalize_target_path(request)
        local target_key = path_to_key(target_path)

        if not group._targets_by_key[target_key] then
            group._targets_by_key[target_key] = {
                path = target_path
            }
        end
    end

    local tasks = {}

    for _, group in pairs(groups) do

        ------------------------------------------------
        -- if we have item targets for a scope, drop
        -- the top-level container target for that scope
        ------------------------------------------------

        local drop_container =
            should_drop_container_target(group._targets_by_key, group.scope)

        for _, target in pairs(group._targets_by_key) do
            local path = target.path

            if not (drop_container and #path == 1 and path[1] == group.scope) then
                group.targets[#group.targets + 1] = target
            end
        end

        group._targets_by_key = nil

        tasks[#tasks + 1] = group
    end

    return tasks
end

return Planner
