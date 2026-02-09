-- pipeline.lua
--
-- Orchestrates config → calc → payout.

local Config  = require("balance.payouts.config")
local Calc    = require("balance.payouts.internal.calc")
local Payout  = require("balance.payouts.internal.payout_per_bf")
local Signals = require("core.diagnostics.signals")

local Pipeline = {}

---@class PipelineOutput
---@field result PayoutResult
---@field total_bf number|nil
---@field signals SignalBag

local function ensure_tables(cfg, sig)
    if type(cfg.categories) ~= "table" then
        Signals.add(sig, "warn", "MISSING_CATEGORIES", "categories", "categories missing; falling back to config defaults", nil)
        cfg.categories = Config.categories
    end
    if type(cfg.contributions) ~= "table" then
        Signals.add(sig, "warn", "MISSING_CONTRIBUTIONS", "contributions", "contributions missing; falling back to config defaults", nil)
        cfg.contributions = Config.contributions
    end
    if type(cfg.job) ~= "table" then
        Signals.add(sig, "warn", "MISSING_JOB", "job", "job missing; falling back to config defaults", nil)
        cfg.job = Config.job
    end
end

local function ensure_job(job, sig)
    if job.pricing_method == nil then
        job.pricing_method = "per_bf"
        Signals.add(sig, "info", "DEFAULT_PRICING_METHOD", "job.pricing_method", "pricing_method defaulted to per_bf", nil)
    end
end

---@param cfg PayoutConfig|table|nil
---@return PayoutResult result, number|nil total_bf, SignalBag signals
function Pipeline.run(cfg)
    local sig = Signals.new()
    cfg = cfg or Config

    if type(cfg) ~= "table" then
        Signals.add(sig, "error", "CFG_NOT_TABLE", "cfg", "cfg must be a table", { got = type(cfg) })
        local empty = { revenue = {}, costs = {}, profit = {}, parties = {}, signals = sig }
        return empty, nil, sig
    end

    ensure_tables(cfg, sig)
    ensure_job(cfg.job, sig)

    local price_per_bf = Calc.sale_price_per_bf(cfg.job, sig)
    local total_bf = cfg.job.total_bf

    local result = Payout.compute_payouts(
        total_bf,
        price_per_bf or -1, -- placeholder; compute_payouts will signal error if invalid
        cfg.categories,
        cfg.contributions,
        sig
    )

    return result, total_bf, sig
end

return Pipeline
