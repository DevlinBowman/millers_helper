-- calc.lua
--
-- Job value evaluation logic with signals.

local Signals = require("core.diagnostics.signals")

local Calc = {}

---@class JobSpec
---@field total_bf number|nil
---@field pricing_method string|nil  -- "per_bf" | "total_value"
---@field sale_price_per_bf number|nil
---@field job_total number|nil

---@param job JobSpec
---@param sig SignalBag
---@return number|nil sale_price_per_bf
function Calc.sale_price_per_bf(job, sig)
    if type(job) ~= "table" then
        Signals.add(sig, "error", "JOB_NOT_TABLE", "job", "job must be a table", { got = type(job) })
        return nil
    end

    local total_bf = job.total_bf
    if type(total_bf) ~= "number" or total_bf <= 0 then
        Signals.add(sig, "error", "BAD_TOTAL_BF", "job.total_bf", "job.total_bf must be a number > 0", { got = total_bf })
        return nil
    end

    local method = job.pricing_method or "per_bf"

    if method == "per_bf" then
        if type(job.sale_price_per_bf) ~= "number" or job.sale_price_per_bf < 0 then
            Signals.add(sig, "error", "BAD_SALE_PRICE_BF", "job.sale_price_per_bf", "sale_price_per_bf must be a number >= 0", { got = job.sale_price_per_bf })
            return nil
        end
        return job.sale_price_per_bf

    elseif method == "total_value" then
        if type(job.job_total) ~= "number" or job.job_total < 0 then
            Signals.add(sig, "error", "BAD_JOB_TOTAL", "job.job_total", "job_total must be a number >= 0", { got = job.job_total })
            return nil
        end
        return job.job_total / total_bf

    else
        Signals.add(sig, "error", "UNKNOWN_PRICING_METHOD", "job.pricing_method", "unknown pricing_method", { got = method })
        return nil
    end
end

return Calc
