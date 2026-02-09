-- view.lua

local view = {}

local function sorted_keys(t)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

local function print_signals(sig)
    if not sig or not sig.items or #sig.items == 0 then
        return
    end

    print("")
    print("SIGNALS")
    print(string.rep("-", 50))

    for _, s in ipairs(sig.items) do
        local head = string.format("[%s] %s @ %s", s.level, s.code, s.path)
        print(head)
        print("  " .. s.message)
        if s.meta then
            -- minimal meta print (avoid deep recursion)
            for k, v in pairs(s.meta) do
                print(string.format("  - %s: %s", tostring(k), tostring(v)))
            end
        end
    end
end

---@param result PayoutResult
---@param total_bf number
---@param opts table|nil { show_signals?: boolean }
function view.print_payout_tree(result, total_bf, opts)
    opts = opts or {}

    print("")
    print("PAYOUT BREAKDOWN")
    print(string.rep("=", 50))
    print(string.format("Total BF:        %d", total_bf or 0))
    print(string.format("Gross Revenue:   $%.2f", (result.revenue and result.revenue.gross) or 0))
    print("")

    for _, party in ipairs(sorted_keys(result.parties)) do
        local buckets = result.parties[party]

        print(party)
        print("│")

        for _, category in ipairs(sorted_keys(buckets)) do
            if category ~= "total" then
                print(string.format("├─ %-12s $%8.2f", category, buckets[category]))
            end
        end

        print("│")
        print(string.format("└─────── %-12s $%8.2f", "TOTAL", buckets.total or 0))
        print("")
    end

    if opts.show_signals then
        print_signals(result.signals)
    end
end

return view
