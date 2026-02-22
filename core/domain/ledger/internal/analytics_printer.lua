-- core/domain/ledger/internal/analytics_printer.lua
--
local Printer = {}

local function pad(str, len)
    str = tostring(str)
    if #str < len then
        return str .. string.rep(" ", len - #str)
    end
    return str
end

local function format_money(v)
    return string.format("$%.2f", v or 0)
end

local function format_bf(v)
    return string.format("%.2f bf", v or 0)
end

----------------------------------------------------------------
-- Section: Header
----------------------------------------------------------------
function Printer.print_header(title)
    print("\n" .. string.rep("=", 65))
    print(" " .. title)
    print(string.rep("=", 65))
end

----------------------------------------------------------------
-- Section: Global Summary
----------------------------------------------------------------
function Printer.print_overview(report)
    Printer.print_header("LEDGER SUMMARY")

    local total_txns = 0
    local total_bf   = 0
    local total_val  = 0

    for _, type_data in pairs(report.by_type) do
        total_txns = total_txns + type_data.txn_count
        total_bf   = total_bf   + type_data.total_bf
        total_val  = total_val  + type_data.total_value
    end

    print(string.format("Total Transactions : %d", total_txns))
    print(string.format("Total Volume       : %s", format_bf(total_bf)))
    print(string.format("Total Value        : %s", format_money(total_val)))
end

----------------------------------------------------------------
-- Section: Breakdown By Type
----------------------------------------------------------------
function Printer.print_by_type(report)
    Printer.print_header("BY TRANSACTION TYPE")

    print(pad("TYPE", 15)
        .. pad("COUNT", 8)
        .. pad("TOTAL BF", 12)
        .. pad("TOTAL $", 12)
        .. pad("AVG $/BF", 12))

    for type_, data in pairs(report.by_type) do
        print(
            pad(type_, 15)
            .. pad(data.txn_count, 8)
            .. pad(format_bf(data.total_bf), 12)
            .. pad(format_money(data.total_value), 12)
            .. pad(format_money(data.avg_value_per_bf), 12)
        )
    end
end

----------------------------------------------------------------
-- Section: Top Buyers
----------------------------------------------------------------
function Printer.print_top_buyers(report, n)
    n = n or 10
    Printer.print_header("TOP BUYERS (BY VALUE)")

    print(pad("BUYER", 25)
        .. pad("COUNT", 8)
        .. pad("TOTAL BF", 12)
        .. pad("TOTAL $", 12)
        .. pad("AVG $/BF", 12))

    for i, r in ipairs(report.rankings.top_buyers_by_value) do
        if i > n then break end
        local k, d = r.key, r.data
        print(
            pad(k, 25)
            .. pad(d.txn_count, 8)
            .. pad(format_bf(d.total_bf), 12)
            .. pad(format_money(d.total_value), 12)
            .. pad(format_money(d.avg_value_per_bf), 12)
        )
    end
end

----------------------------------------------------------------
-- Section: Top Users
----------------------------------------------------------------
function Printer.print_top_users(report, n)
    n = n or 10
    Printer.print_header("TOP USERS (BY WOOD VOLUME)")

    print(pad("CLAIMANT", 25)
        .. pad("COUNT", 8)
        .. pad("TOTAL BF", 12)
        .. pad("TOTAL $", 12)
        .. pad("AVG $/BF", 12))

    for i, r in ipairs(report.rankings.top_users_by_bf) do
        if i > n then break end
        local k, d = r.key, r.data
        print(
            pad(k, 25)
            .. pad(d.txn_count, 8)
            .. pad(format_bf(d.total_bf), 12)
            .. pad(format_money(d.total_value), 12)
            .. pad(format_money(d.avg_value_per_bf), 12)
        )
    end
end

----------------------------------------------------------------
-- Section: Personal Use Summary
----------------------------------------------------------------
function Printer.print_personal_use(report)
    Printer.print_header("PERSONAL USE SUMMARY")

    local pu = report.personal_use

    print(string.format("Count          : %d", pu.txn_count))
    print(string.format("Total BF       : %s", format_bf(pu.total_bf)))
    print(string.format("Total Value    : %s", format_money(pu.total_value)))
    print(string.format("Avg Value/BF   : %s", format_money(pu.avg_value_per_bf)))
end

----------------------------------------------------------------
-- Master Print
----------------------------------------------------------------
function Printer.print_full(report)
    Printer.print_overview(report)
    Printer.print_by_type(report)
    Printer.print_top_buyers(report)
    Printer.print_top_users(report)
    Printer.print_personal_use(report)
end

function Printer.build_full_text(report)
    local buffer = {}

    local function line(str)
        buffer[#buffer + 1] = str
    end

    local function header(title)
        line("")
        line(string.rep("=", 80))
        line(" " .. title)
        line(string.rep("=", 80))
    end

    local function pad(str, len)
        str = tostring(str)
        if #str < len then
            return str .. string.rep(" ", len - #str)
        end
        return str
    end

    local function money(v)
        return string.format("$%.2f", v or 0)
    end

    local function bf(v)
        return string.format("%.2f bf", v or 0)
    end

    ------------------------------------------------------------
    -- Overview
    ------------------------------------------------------------
    header("LEDGER SUMMARY")

    local total_txns = 0
    local total_bf   = 0
    local total_val  = 0

    for _, t in pairs(report.by_type) do
        total_txns = total_txns + t.txn_count
        total_bf   = total_bf   + t.total_bf
        total_val  = total_val  + t.total_value
    end

    line("Total Transactions : " .. total_txns)
    line("Total Volume       : " .. bf(total_bf))
    line("Total Value        : " .. money(total_val))

    ------------------------------------------------------------
    -- By Type
    ------------------------------------------------------------
    header("BY TRANSACTION TYPE")

    line(pad("TYPE", 15)
        .. pad("COUNT", 8)
        .. pad("TOTAL BF", 14)
        .. pad("TOTAL $", 14)
        .. pad("AVG $/BF", 14))

    for type_, d in pairs(report.by_type) do
        line(
            pad(type_, 15)
            .. pad(d.txn_count, 8)
            .. pad(bf(d.total_bf), 14)
            .. pad(money(d.total_value), 14)
            .. pad(money(d.avg_value_per_bf), 14)
        )
    end

    return table.concat(buffer, "\n")
end

return Printer
