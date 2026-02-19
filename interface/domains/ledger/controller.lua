-- interface/domains/ledger/controller.lua

local Runtime = require("core.domain.runtime.controller")
local Ledger  = require("core.domain.ledger.controller")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({
        _ledger_path = nil, -- optional, used only for display / future wiring
    }, Controller)
end

----------------------------------------------------------------
-- Small helpers
----------------------------------------------------------------

local function money(v)
    return string.format("$%.2f", tonumber(v or 0) or 0)
end

local function order_number_of(order)
    order = order or {}
    return order.order_number or order.order_id or order.id or "unknown"
end

local function safe_txn_id(t)
    return (t and t.transaction_id) or "unknown"
end

local function print_ledger_help()
    print("ledger commands:")
    print("  ledger <path>            set ledger path (display / future wiring)")
    print("  inspect                  list ledger index (summary rows)")
    print("  browse                   same as inspect (alias)")
    print("  open <id|index>          open full bundle by txn id or row index")
    print("  ingest <input_path>      runtime load -> ledger commit (order batches only)")
    print("  browser                  interactive arrow browser")
end

local function parse_open_selector(selector, transactions)
    if not selector or selector == "" then
        return nil, "missing selector"
    end

    -- numeric index
    local idx = tonumber(selector)
    if idx and transactions and transactions[idx] then
        return transactions[idx].transaction_id, nil
    end

    -- assume txn id
    return selector, nil
end

----------------------------------------------------------------
-- Set ledger path (currently informational)
----------------------------------------------------------------

function Controller:ledger(ctx)
    local path = ctx.positionals[1]
    if not path then
        print_ledger_help()
        return
    end

    self._ledger_path = path
    print("ledger set")
end

----------------------------------------------------------------
-- Inspect / Browse (index only)
----------------------------------------------------------------

function Controller:inspect(_ctx)
    local result = Ledger.read_all()
    local txns   = (result and result.transactions) or {}

    print("")
    print("ID            | DATE       | TYPE     | BF       | VALUE")
    print(string.rep("-", 60))

    for _, t in ipairs(txns) do
        print(string.format(
            "%-13s | %-10s | %-8s | %-8s | %s",
            tostring(t.transaction_id),
            tostring(t.date),
            tostring(t.type),
            tostring(t.total_bf or 0),
            money(t.value)
        ))
    end

    print("")
    print("transactions: " .. tostring(#txns))
    return result
end

function Controller:browse(ctx)
    return self:inspect(ctx)
end

----------------------------------------------------------------
-- Open full bundle
----------------------------------------------------------------

function Controller:open(ctx)
    local selector = ctx.positionals[1]
    if not selector then
        print_ledger_help()
        return
    end

    local index = Ledger.read_all()
    local txns  = (index and index.transactions) or {}

    local txn_id, err = parse_open_selector(selector, txns)
    if err then
        io.stderr:write("error: " .. tostring(err) .. "\n")
        return
    end

    local bundle = Ledger.read_bundle(txn_id)
    if not bundle then
        io.stderr:write("error: bundle not found for " .. tostring(txn_id) .. "\n")
        return
    end

    local entry  = bundle.entry or {}
    local order  = bundle.order or {}
    local boards = bundle.boards or {}

    print("")
    print("=== TRANSACTION ===")
    print("txn_id:   " .. tostring(entry.transaction_id))
    print("date:     " .. tostring(entry.date))
    print("type:     " .. tostring(entry.type))
    print("value:    " .. money(entry.value))
    print("total_bf: " .. tostring(entry.total_bf or 0))
    print("")
    print("=== ORDER ===")
    print("order_number: " .. tostring(order_number_of(order)))
    print("client:       " .. tostring(order.client or order.customer_name or order.customer_id or ""))
    print("claimant:     " .. tostring(order.claimant or ""))
    print("")
    print("=== BOARDS ===")
    print("count: " .. tostring(#boards))

    -- short preview
    local preview_n = math.min(#boards, 10)
    for i = 1, preview_n do
        local b = boards[i] or {}
        print(string.format(
            "%02d | %s | %sx%sx%s | bf=%s | $/bf=%s",
            i,
            tostring(b.label or b.id or ""),
            tostring(b.h or b.base_h or ""),
            tostring(b.w or b.base_w or ""),
            tostring(b.l or ""),
            tostring(b.bf_batch or b.bf_ea or ""),
            tostring(b.bf_price or "")
        ))
    end
end

----------------------------------------------------------------
-- Ingest (runtime load -> ledger commit)
----------------------------------------------------------------

function Controller:ingest(ctx)
    local input_path = ctx.positionals[1]
    if not input_path then
        print_ledger_help()
        return
    end

    local runtime = Runtime.load(input_path, { name = "ledger_ingest", category = "order" })
    local result  = Ledger.commit(runtime, { force = ctx.flags.force })

    print("ingested: " .. tostring(#(result.transactions or {})))
    return result
end

----------------------------------------------------------------
-- Interactive Browser (arrow keys)
----------------------------------------------------------------

local function term_raw_on()
    os.execute("stty -echo -icanon min 1 time 0")
end

local function term_raw_off()
    os.execute("stty echo icanon")
end

local function clear_screen()
    io.write("\27[2J\27[H")
end

local function read_key()
    local ch = io.read(1)

    if ch == "\27" then
        local n1 = io.read(1)
        local n2 = io.read(1)
        if n1 == "[" then
            if n2 == "A" then return "up" end
            if n2 == "B" then return "down" end
            if n2 == "C" then return "right" end
            if n2 == "D" then return "left" end
        end
        return "esc"
    end

    if ch == "\r" or ch == "\n" then return "enter" end
    return ch
end

local function render_browser(txns, selected)
    clear_screen()
    print("=== LEDGER BROWSER ===")
    print("↑/↓ move | Enter open | q quit")
    print("")
    print("IDX | ID            | DATE       | TYPE     | BF       | VALUE")
    print(string.rep("-", 75))

    for i, t in ipairs(txns) do
        local cursor = (i == selected) and ">" or " "
        print(string.format(
            "%s%03d | %-13s | %-10s | %-8s | %-8s | %s",
            cursor,
            i,
            tostring(t.transaction_id),
            tostring(t.date),
            tostring(t.type),
            tostring(t.total_bf or 0),
            money(t.value)
        ))
    end

    print("")
    print("transactions: " .. tostring(#txns))
end

function Controller:browser()
    local index = Ledger.read_all()
    local txns  = (index and index.transactions) or {}

    if #txns == 0 then
        print("ledger empty")
        return
    end

    local selected = 1

    term_raw_on()
    local ok, err = pcall(function()
        while true do
            render_browser(txns, selected)

            local key = read_key()

            if key == "up" then
                selected = math.max(1, selected - 1)
            elseif key == "down" then
                selected = math.min(#txns, selected + 1)
            elseif key == "enter" then
                term_raw_off()
                self:open({ positionals = { tostring(selected) } })
                io.write("\npress any key to return...")
                term_raw_on()
                io.read(1)
            elseif key == "q" then
                break
            end
        end
    end)

    term_raw_off()
    clear_screen()

    if not ok then
        error(err, 0)
    end
end

return Controller
