-- order_context/controller.lua
--
-- Boundary surface for order_context module.
--
-- RULE:
--   • Only canonical domain data leaves this boundary.
--   • Diagnostics (signals, decisions) flow vertically via Diagnostic bus.
--

local Contract   = require("core.contract")
local Trace      = require("tools.trace.trace")
local Diagnostic = require("tools.diagnostic")

local ResolveGroupPipeline = require("platform.order_context.pipelines.resolve_group")
local CompressPipeline     = require("platform.order_context.pipelines.compress")

local Controller = {}

----------------------------------------------------------------
-- Contracts (Domain Only)
----------------------------------------------------------------

Controller.CONTRACT = {

    resolve_group = {
        in_ = {
            rows = true,
            opts = false,
        },
        out = {
            order = true,
        },
    },

    compress = {
        in_ = {
            rows         = true,
            identity_key = true,
            opts         = false,
        },
        out = {
            groups = true,
        },
    },
}

----------------------------------------------------------------
-- resolve_group
----------------------------------------------------------------

--- Resolve distributed order fragments for a single group.
--- @return table result { order=table }
function Controller.resolve_group(rows, opts)

    Trace.contract_enter("order_context.controller.resolve_group")
    Trace.contract_in({ rows = rows, opts = opts })

    Contract.assert(
        { rows = rows, opts = opts },
        Controller.CONTRACT.resolve_group.in_
    )

    assert(type(rows) == "table", "order_context.resolve_group(): rows array required")
    if opts ~= nil then
        assert(type(opts) == "table", "order_context.resolve_group(): opts must be table|nil")
    end

    local ok, pipeline_result, scope =
        Diagnostic.with_scope("order_context.resolve_group", function()
            return ResolveGroupPipeline.run(rows, opts)
        end)

    if not ok then
        -- programmer bug inside pipeline
        error(pipeline_result)
    end

    if not pipeline_result then
        Trace.contract_leave()
        return nil, scope or {
            kind = "order_context_resolve_failure"
        }
    end

    local order = pipeline_result.order
    if type(order) ~= "table" then
        error("resolve_group(): missing canonical order")
    end

    local result = { order = order }

    Contract.assert(result, Controller.CONTRACT.resolve_group.out)
    Trace.contract_out(result)
    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- compress
----------------------------------------------------------------

--- Group classified rows by identity and resolve order context per group.
--- @return table result { groups = table[] }
function Controller.compress(rows, identity_key, opts)

    Trace.contract_enter("order_context.controller.compress")
    Trace.contract_in({ rows = rows, identity_key = identity_key, opts = opts })

    Contract.assert(
        { rows = rows, identity_key = identity_key, opts = opts },
        Controller.CONTRACT.compress.in_
    )

    assert(type(rows) == "table", "order_context.compress(): rows array required")
    assert(type(identity_key) == "string", "order_context.compress(): identity_key string required")
    if opts ~= nil then
        assert(type(opts) == "table", "order_context.compress(): opts must be table|nil")
    end

    local groups, compress_err = CompressPipeline.run(rows, identity_key, opts)

    if not groups then
        Trace.contract_leave()
        return nil, compress_err
    end

    local result = { groups = groups }

    Contract.assert(result, Controller.CONTRACT.compress.out)
    Trace.contract_out(result)
    Trace.contract_leave()

    return result
end

return Controller
