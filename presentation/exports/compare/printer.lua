-- presentation/exports/compare/printer.lua
--
-- Stdout renderer for ComparisonModel.
--
-- JOB TOTALS behavior:
--   • "our price" is the baseline
--   • external sources include post-tax totals
--   • %Δ columns compare against our price
--   • fixed-width, human-readable table
--   • deterministic ordering

local M = {}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local SALES_TAX_RATE = 0.085 -- 8.5%

----------------------------------------------------------------
-- Column widths
----------------------------------------------------------------

local COL = {
    source = 26,
    total  = 10,
    pct    = 8,
    tax    = 12,
    pcttax = 10,
}

----------------------------------------------------------------
-- Formatting helpers
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
-- Printer
----------------------------------------------------------------

function M.print(model)
    ----------------------------------------------------------------
    -- JOB TOTAL SUMMARY
    ----------------------------------------------------------------

    print(("="):rep(110))
    print("JOB TOTALS")
    print(
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

    -- ordering: our price first, then alphabetical
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

        print(
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

    print(("="):rep(110))
end

return M
