-- core/price_suggestion/formats/text.lua
--
-- Fixed-width formatter for price suggestion scenarios.
-- NO sinks. Returns lines.

local Text = {}

local function money(n)
    return n and string.format("$%.2f", n) or "-"
end

local function pct(n)
    return n and string.format("%.1f%%", n) or "—"
end

local function ljust(s, w)
    return string.format("%-" .. w .. "s", tostring(s))
end

local function rjust(s, w)
    return string.format("%" .. w .. "s", tostring(s))
end

function Text.format(result)
    local out = {}

    local W = {
        option = 28,
        total  = 12,
        perbf  = 10,
        cost   = 12,
        profit = 12,
        margin = 9,
        flag   = 8,
    }

    local function emit(s) out[#out + 1] = s end

    emit(string.rep("=", 92))
    emit("PRICE SUGGESTIONS")
    emit(string.rep("-", 92))

    for _, sc in ipairs(result.scenarios or {}) do
        local job = sc.job
        emit(
            ljust(sc.name, W.option) .. " " ..
            rjust(money(job.revenue), W.total) .. " " ..
            rjust(money(job.bf_price), W.perbf) .. " " ..
            rjust(money(job.costs.total), W.cost) .. " " ..
            rjust(money(job.profit.dollars), W.profit) .. " " ..
            rjust(pct(job.profit.pct), W.margin) .. " " ..
            ljust(job.profit.negative and "LOSS" or "", W.flag)
        )
    end

    emit(string.rep("=", 92))
    return { kind = "text", lines = out }
end

return Text
