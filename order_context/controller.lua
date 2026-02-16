-- order_context/controller.lua
--
-- Boundary surface for order_context module.
--
-- Responsibilities:
--   • Define contracts
--   • Trace
--   • Validate runtime inputs/outputs
--   • Delegate to pipelines
--
-- Exposes:
--   • resolve_group(rows, opts)
--   • compress(rows, identity_key, opts)

local Contract = require("core.contract")
local Trace    = require("tools.trace.trace")

local ResolveGroupPipeline = require("order_context.pipelines.resolve_group")
local CompressPipeline     = require("order_context.pipelines.compress")

local Controller = {}

----------------------------------------------------------------
-- Contracts
----------------------------------------------------------------

Controller.CONTRACT = {

    resolve_group = {
        in_ = {
            rows = true,
            opts = false,
        },
        out = {
            order     = true,
            signals   = true,
            decisions = true,
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
--- @param rows table[] classified rows
--- @param opts table|nil
--- @return table result { order=table, signals=table[], decisions=table }
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

    local result = ResolveGroupPipeline.run(rows, opts)

    Contract.assert(result, Controller.CONTRACT.resolve_group.out)
    Trace.contract_out(result)

    Trace.contract_leave()
    return result
end

----------------------------------------------------------------
-- compress
----------------------------------------------------------------

--- Group classified rows by identity and resolve order context per group.
--- Replaces legacy compression module.
---
--- @param rows table[] classified rows
--- @param identity_key string
--- @param opts table|nil
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

    local groups = CompressPipeline.run(rows, identity_key, opts)

    local result = { groups = groups }

    Contract.assert(result, Controller.CONTRACT.compress.out)
    Trace.contract_out(result)

    Trace.contract_leave()
    return result
end

return Controller
