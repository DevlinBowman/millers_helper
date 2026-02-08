-- presentation/exports/compare/printer.lua
--
-- Formatter for ComparisonModel.
--
-- Produces text output identical to the legacy stdout renderer,
-- but returns lines instead of printing them.
--
-- NO I/O. Presentation-only.

local Layout = require("core.compare.formats.layout")

local M = {}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local SALES_TAX_RATE = 0.085 -- 8.5%

local HR  = ("-"):rep(110)
local HHR = ("="):rep(110)

----------------------------------------------------------------
-- Column widths (JOB TOTALS – DO NOT CHANGE)
----------------------------------------------------------------

local COL = {
    source = 26,
    total  = 10,
    pct    = 8,
    tax    = 12,
    pcttax = 10,
}

----------------------------------------------------------------
-- Formatting helpers (unchanged semantics)
----------------------------------------------------------------

local function money(n)
    return n and string.format("$%.2f", n) or nil
end

local function pct(n)
    if n == nil then return nil end
    local sign = n > 0 and "+" or ""
    return string.format("%s%.1f%%", sign, n)
end

local function ljust(s, w)
    s = tostring(s or "")
    if #s > w then return s:sub(1, w) end
    return string.format("%-" .. w .. "s", s)
end

local function rjust(s, w)
    s = tostring(s or "")
    if #s > w then return s:sub(1, w) end
    return string.format("%" .. w .. "s", s)
end

local function blank(w)
    return string.format("%" .. w .. "s", "—")
end

local function basename(path)
    path = tostring(path or "")
    local name = path:match("([^/]+)$") or path
    return name:gsub("%.txt$", "")
end

local function display_source(src)
    if src == "input" then
        return "our price"
    end
    return basename(src)
end

local function with_tax(total)
    return total * (1 + SALES_TAX_RATE)
end

----------------------------------------------------------------
-- Formatter
----------------------------------------------------------------

function M.format(model)
    local out = {}

    local function emit(line)
        out[#out + 1] = line
    end

    ----------------------------------------------------------------
    -- BOARD COMPARISON
    ----------------------------------------------------------------

    emit(HHR)
    emit("BOARD COMPARISON")
    emit(HR)

    -- header
    do
        local line = (" "):rep(2)
        for _, col in ipairs(Layout.header) do
            local label, width, align = col[1], col[2], col[3]
            if align == "R" then
                line = line .. rjust(label, width)
            else
                line = line .. ljust(label, width)
            end
            line = line .. " "
        end
        emit(line)
    end

    emit(HR)

    for _, row in ipairs(model.rows or {}) do
        local ob = row.order_board
        local board_label = ob.id or ob.label or ""

        emit((" "):rep(2) .. "[" .. board_label .. "]")
        emit(HR)

        -- deterministic ordering
        local sources = {}
        for src in pairs(row.offers or {}) do
            sources[#sources + 1] = src
        end
        table.sort(sources, function(a, b)
            if a == "input" then return true end
            if b == "input" then return false end
            return a < b
        end)

        for _, src in ipairs(sources) do
            local offer = row.offers[src]
            local pr    = offer.pricing or {}
            local meta  = offer.meta or {}

            local line = (" "):rep(2)
            local values = {
                display_source(src),
                meta.label or board_label,
                money(pr.ea),
                money(pr.lf),
                pr.bf,
                money(pr.total),
                meta.match_type,
            }

            for i, col in ipairs(Layout.header) do
                local width, align = col[2], col[3]
                local v = values[i]
                if align == "R" then
                    line = line .. rjust(v, width)
                else
                    line = line .. ljust(v, width)
                end
                line = line .. " "
            end

            emit(line)
        end

        emit(HR)
    end

    ----------------------------------------------------------------
    -- JOB TOTAL SUMMARY (VISUALLY IDENTICAL)
    ----------------------------------------------------------------

    emit(HHR)
    emit("JOB TOTALS")
    emit(
        (" "):rep(2) ..
        ljust("Source", COL.source) ..
        " " ..
        rjust("Total", COL.total) ..
        " " ..
        rjust("%Δ", COL.pct) ..
        " " ..
        rjust("Total+Tax", COL.tax) ..
        " " ..
        rjust(" %Δ+Tax", COL.pcttax)
    )

    local our_total =
        model.totals
        and model.totals["input"]
        and model.totals["input"].total
        or 0

    local names = {}
    for k in pairs(model.totals or {}) do
        names[#names + 1] = k
    end
    table.sort(names, function(a, b)
        if a == "input" then return true end
        if b == "input" then return false end
        return a < b
    end)

    for _, src in ipairs(names) do
        local t = model.totals[src] or {}
        local pre = t.total or 0

        local post, d_pre, d_post

        if src ~= "input" then
            post = with_tax(pre)
            if our_total > 0 then
                d_pre  = ((pre  - our_total) / our_total) * 100
                d_post = ((post - our_total) / our_total) * 100
            end
        end

        emit(
            (" "):rep(2) ..
            ljust(display_source(src), COL.source) ..
            " " ..
            rjust(money(pre), COL.total) ..
            " " ..
            rjust(pct(d_pre), COL.pct) ..
            " " ..
            (src ~= "input"
                and rjust(money(post), COL.tax)
                or blank(COL.tax)) ..
            " " ..
            (src ~= "input"
                and rjust(pct(d_post), COL.pcttax)
                or blank(COL.pcttax))
        )
    end

    emit(HHR)

    return {
        kind  = "text",
        lines = out,
    }
end

return M
