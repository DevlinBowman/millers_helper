-- core/domain/enrichment/engine.lua

local Cases = require("core.domain.enrichment.cases")
local Schema = require("core.schema")
local Dispatcher = require("core.domain.enrichment.dispatcher")
local Planner  = require("core.domain.enrichment.planner")
local Executor = require("core.domain.enrichment.executor")

local Engine = {}

------------------------------------------------------------
-- helpers
------------------------------------------------------------

local function state_matches(state, checks)
    if not checks then
        return false
    end

    for _, check in ipairs(checks) do
        if check == "is_incomplete" then
            if state ~= "complete" then
                return true
            end
        end

        if check == "is_nil" then
            if state == "nil" then
                return true
            end
        end

        if check == "is_empty" then
            if state == "empty" then
                return true
            end
        end

        if check == "is_zero" then
            if state == "0" then
                return true
            end
        end
    end

    return false
end

------------------------------------------------------------
-- rule field matcher
------------------------------------------------------------

local function field_matches_case(node, case, path)
    if not node then
        return false
    end

    ------------------------------------------------
    -- scope match (container rules)
    ------------------------------------------------

    if case.scope then
        if path[#path] == case.scope then
            return true
        end
    end

    ------------------------------------------------
    -- group match
    ------------------------------------------------

    if case.fields and case.fields.group then
        for _, g in ipairs(node.groups or {}) do
            if g == case.fields.group then
                return true
            end
        end
    end

    ------------------------------------------------
    -- explicit field names
    ------------------------------------------------

    if case.fields and case.fields.names then
        for _, name in ipairs(case.fields.names) do
            if node.name == name then
                return true
            end
        end
    end

    return false
end

------------------------------------------------------------
-- emit request
------------------------------------------------------------

local function emit_request(case_name, case, path, node)
    return {
        case    = case_name,
        message = case.message,

        service = case.service,
        package = case.package,

        scope   = case.scope,

        field   = node.name,
        state   = node.state,
        path    = path
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
            walk_fields(
                node.child.fields,
                node_path,
                cases,
                requests
            )
        end

        if node.items then
            for index, item in pairs(node.items) do
                local item_path = { table.unpack(node_path) }
                item_path[#item_path + 1] = index

                walk_fields(
                    item.fields,
                    item_path,
                    cases,
                    requests
                )
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

    ------------------------------------------------------------
    -- capability scan (engine owns this)
    ------------------------------------------------------------

    local audit = Schema.object.audit(domain, object)
    local capabilities = audit.capabilities()

    ------------------------------------------------------------
    -- rule evaluation
    ------------------------------------------------------------

    local requests = {}

    walk_fields(
        capabilities.fields,
        {},
        Cases,
        requests
    )

    ------------------------------------------------------------
    -- normalized result
    ------------------------------------------------------------

    return {
        capabilities = capabilities,
        requests     = requests
    }
end


function Engine.execute(domain, object, opts)

    local result = Engine.run(domain, object)

    local tasks =
        Planner.compile(object, result.requests)

    Executor.run(object, tasks, opts)

    result.tasks = tasks

    return result
end
return Engine
