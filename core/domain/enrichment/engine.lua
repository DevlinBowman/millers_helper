-- core/domain/enrichment/engine.lua

local Cases    = require("core.domain.enrichment.cases")
local Schema   = require("core.schema")
local Planner  = require("core.domain.enrichment.planner")
local Executor = require("core.domain.enrichment.executor")
local Mutator  = require("core.domain.enrichment.mutate")

local Engine = {}

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function state_matches(state, checks)
    if not checks then
        return false
    end

    for _, check in ipairs(checks) do
        if check == "is_incomplete" and state ~= "complete" then
            return true
        end

        if check == "is_nil" and state == "nil" then
            return true
        end

        if check == "is_empty" and state == "empty" then
            return true
        end

        if check == "is_zero" and state == "0" then
            return true
        end
    end

    return false
end

local function field_matches_case(node, case, path)

    if not node then
        return false
    end

    local has_field_filters =
        case.fields ~= nil
        and (
            case.fields.group ~= nil
            or (case.fields.names ~= nil and #case.fields.names > 0)
        )

    ------------------------------------------------
    -- field-filtered cases:
    -- match only actual field metadata
    ------------------------------------------------

    if has_field_filters then

        if case.fields.group then
            for _, g in ipairs(node.groups or {}) do
                if g == case.fields.group then
                    return true
                end
            end
        end

        if case.fields.names then
            for _, name in ipairs(case.fields.names) do
                if node.name == name then
                    return true
                end
            end
        end

        return false
    end

    ------------------------------------------------
    -- scope-only cases:
    -- match container path only when there are
    -- no field filters
    ------------------------------------------------

    if case.scope then
        return path[#path] == case.scope
    end

    return false
end

local function normalize_target(path, scope)

    if not scope then
        return path
    end

    if path[1] ~= scope then
        return path
    end

    ------------------------------------------------
    -- collection item target
    ------------------------------------------------

    if type(path[2]) == "number" then
        return { path[1], path[2] }
    end

    ------------------------------------------------
    -- container target
    ------------------------------------------------

    return { path[1] }

end


local function emit_request(case_name, case, path, node)

    return {
        case    = case_name,
        message = case.message,

        service = case.service,
        package = case.package,
        scope   = case.scope,

        field   = node.name,
        state   = node.state,

        path    = path,
        target  = normalize_target(path, case.scope)
    }

end

------------------------------------------------------------
-- recursive capability walker
------------------------------------------------------------

local function walk_fields(fields, path, cases, requests)
    for name, node in pairs(fields or {}) do
        local node_path = { table.unpack(path) }
        node_path[#node_path + 1] = name

        ------------------------------------------------
        -- evaluate cases
        ------------------------------------------------

        for case_name, case in pairs(cases) do
            if field_matches_case(node, case, node_path)
                and state_matches(node.state, case.checks)
            then
                requests[#requests + 1] =
                    emit_request(case_name, case, node_path, node)
            end
        end

        ------------------------------------------------
        -- recurse children
        ------------------------------------------------

        if node.child then
            walk_fields(node.child.fields, node_path, cases, requests)
        end

        if node.items then
            for index, item in pairs(node.items) do
                local item_path = { table.unpack(node_path) }
                item_path[#item_path + 1] = index

                walk_fields(item.fields, item_path, cases, requests)
            end
        end
    end
end

------------------------------------------------------------
-- run rule engine
------------------------------------------------------------

function Engine.run(domain, object)
    if not domain then
        error("[enrichment.engine] domain required")
    end

    if not object then
        error("[enrichment.engine] runtime object required")
    end

    local audit = Schema.object.audit(domain, object)
    local capabilities = audit.capabilities()

    local requests = {}

    walk_fields(
        capabilities.fields,
        {},
        Cases,
        requests
    )

    return {
        capabilities = capabilities,
        requests     = requests,
    }
end

------------------------------------------------------------
-- execute orchestration
------------------------------------------------------------

function Engine.execute(domain, object, opts)
    opts = opts or {}

    local result = Engine.run(domain, object)

    local tasks = Planner.compile(object, result.requests)
    local execution = Executor.run(object, tasks, opts)
    local patches = execution.patches or {}

    if #patches > 0 then
        Mutator.apply(object, patches)
    end

    result.tasks = tasks
    result.patches = patches
    result.skipped = execution.skipped or {}

    return result
end

return Engine
