-- adapter.lua
--
-- Public adapter for payout calculation.
-- Responsible for:
--   • defining canonical spec
--   • merging user overrides
--   • applying defaults
--   • running the pipeline
--   • returning signals for debugging

local Pipeline = require("balance.payouts.internal.pipeline")
local Default  = require("balance.payouts.config")
local Signals  = require("core.diagnostics.signals")

local Adapter = {}

---@class AdapterSpec
---@field categories table<string, CategoryMeta>|nil
---@field job JobSpec|nil
---@field contributions table<string, table<string, number>>|nil

local function deep_merge(base, override)
    if override == nil then
        return base
    end

    local out = {}
    for k, v in pairs(base or {}) do
        out[k] = v
    end

    for k, v in pairs(override or {}) do
        if type(v) == "table" and type(out[k]) == "table" then
            out[k] = deep_merge(out[k], v)
        else
            out[k] = v
        end
    end

    return out
end

---@param overrides AdapterSpec|nil
---@return PayoutConfig spec
local function build_spec(overrides)
    overrides = overrides or {}

    local spec = {
        categories    = deep_merge(Default.categories, overrides.categories),
        job           = deep_merge(Default.job, overrides.job),
        contributions = deep_merge(Default.contributions, overrides.contributions),
    }

    return spec
end

local function validate_spec_shape(spec, sig)
    if type(spec) ~= "table" then
        Signals.add(sig, "error", "SPEC_NOT_TABLE", "spec", "spec must be a table", { got = type(spec) })
        return
    end
    if type(spec.job) ~= "table" then
        Signals.add(sig, "error", "JOB_MISSING", "spec.job", "job spec required", { got = type(spec.job) })
    end
    if type(spec.categories) ~= "table" then
        Signals.add(sig, "error", "CATEGORIES_MISSING", "spec.categories", "categories required", { got = type(spec.categories) })
    end
    if type(spec.contributions) ~= "table" then
        Signals.add(sig, "error", "CONTRIB_MISSING", "spec.contributions", "contributions required", { got = type(spec.contributions) })
    end
end

---@param overrides AdapterSpec|nil
---@return PayoutResult result, number|nil total_bf, PayoutConfig spec, SignalBag signals
function Adapter.run(overrides)
    local sig = Signals.new()
    local spec = build_spec(overrides)
    validate_spec_shape(spec, sig)

    if sig.has_error then
        local empty = { revenue = {}, costs = {}, profit = {}, parties = {}, signals = sig }
        return empty, nil, spec, sig
    end

    local result, total_bf, pipeline_sig = Pipeline.run(spec)

    -- Pipeline returns its own signal bag; keep one canonical bag (pipeline's)
    -- and ensure adapter shape errors are also included (if any).
    for _, item in ipairs(sig.items) do
        Signals.add(pipeline_sig, item.level, item.code, item.path, item.message, item.meta)
    end

    result.signals = pipeline_sig
    return result, total_bf, spec, pipeline_sig
end

return Adapter
