-- classify/controller.lua
--
-- Public boundary surface for the classify domain.
--
-- PURPOSE
-- -------
-- Provide a stable entrypoint into classification logic with:
--   • Contract enforcement
--   • Trace instrumentation
--   • Controlled error propagation
--
-- This controller:
--   • Validates input shape
--   • Delegates to classify.pipelines.object
--   • Validates output shape
--   • Emits trace events for contract boundaries
--
-- This controller does NOT:
--   • Perform alias resolution itself
--   • Perform domain ownership logic
--   • Perform reconciliation
--   • Contain classification behavior
--
-- All classification logic lives in pipelines.object.

local objectPipeline = require("platform.classify.pipelines.object")
local Trace          = require("tools.trace.trace")
local Contract       = require("core.contract")

local Controller = {}

----------------------------------------------------------------
-- Contract
--
-- Defines the structural boundary of this domain surface.
--
-- INPUT:
--   object (flat decoded attribute map)
--
-- OUTPUT:
--   {
--     board       = table,
--     order       = table,
--     unknown     = table,
--     diagnostics = table,
--   }
----------------------------------------------------------------

Controller.CONTRACT = {
    object = {
        in_ = {
            object = true,
        },
        out = {
            board       = true,
            order       = true,
            unknown     = true,
            diagnostics = true,
        },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Classify a single decoded object into canonical domain partitions.
---
--- This function enforces the classify domain boundary:
---   • Input shape must match contract
---   • Output shape must match contract
---   • Internal errors are normalized
---
--- @param object table
--- @return table result
function Controller.object(object)
    ----------------------------------------------------------------
    -- Enter contract boundary (trace)
    ----------------------------------------------------------------
    Trace.contract_enter("classify.controller.object")
    Trace.contract_in(Controller.CONTRACT.object.in_)

    ----------------------------------------------------------------
    -- Execute classification inside protected call
    --
    -- pcall ensures:
    --   • internal assertion failures surface cleanly
    --   • trace leave always executes
    ----------------------------------------------------------------
    local ok, result_or_err = pcall(function()

        ------------------------------------------------------------
        -- Validate input shape
        ------------------------------------------------------------
        Contract.assert(
            { object = object },
            Controller.CONTRACT.object.in_
        )

        ------------------------------------------------------------
        -- Delegate to pipeline (pure classification logic)
        ------------------------------------------------------------
        local result = objectPipeline.run(object)

        ------------------------------------------------------------
        -- Validate output shape
        ------------------------------------------------------------
        Contract.assert(
            result,
            Controller.CONTRACT.object.out
        )

        ------------------------------------------------------------
        -- Emit contract out trace
        ------------------------------------------------------------
        Trace.contract_out(
            Controller.CONTRACT.object.out,
            "classify.pipeline.object",
            "caller"
        )

        return result
    end)

    ----------------------------------------------------------------
    -- Leave contract boundary
    ----------------------------------------------------------------
    Trace.contract_leave()

    ----------------------------------------------------------------
    -- Normalize error propagation
    --
    -- We rethrow without altering stack level (level 0)
    -- to avoid masking original error context.
    ----------------------------------------------------------------
    if not ok then
        error(result_or_err, 0)
    end

    return result_or_err
end

return Controller
