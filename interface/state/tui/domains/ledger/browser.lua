-- interface/tui/domains/ledger.lua

local Menu   = require("interface.tui.menu")
local Term   = require("interface.tui.term")

local Runtime = require("core.domain.runtime.controller")
local Ledger  = require("core.domain.ledger.controller")

local Format  = require("interface.domains.ledger.format")      -- you already have
local Browser = require("interface.domains.ledger.browser")     -- we will rewrite to use Term below

local DOMAIN = {
    name = "ledger",
    description = "ledger inspect/open/ingest/browser",
}

local STATE_KEY = "ledger.path"

local function resolve_ledger_path(services)
    local state = services.state
    local path = state:get(STATE_KEY)

    if not path or path == "" then
        io.write("ledger path not set. Enter path: ")
        local input = io.read()
        input = input and input:gsub("^%s+", ""):gsub("%s+$", "") or ""
        if input == "" then
            io.stderr:write("ledger required\n")
            return nil
        end
        state:set(STATE_KEY, input)
        print("ledger set:", input)
        return input
    end

    return path
end

local function help_text()
    return table.concat({
        "ledger menu:",
        "  set <path>      set ledger path",
        "  show            show current ledger",
        "  inspect         list transactions",
        "  open <id|idx>   open bundle",
        "  ingest <path>   ingest order input -> commit",
        "  browser         interactive browser",
        "  back            return to app menu",
        "  q               quit program",
    }, "\n")
end

local function cmd_set(services, path)
    if not path or path == "" then
        io.stderr:write("missing path\n")
        return
    end
    services.state:set(STATE_KEY, path)
    print("ledger set:", path)
end

local function cmd_show(services)
    local p = services.state:get(STATE_KEY)
    if p then print("current ledger:", p) else print("no ledger set") end
end

local function cmd_inspect(services)
    local path = resolve_ledger_path(services)
    if not path then return end

    local result = Ledger.read_all({ ledger_path = path })
    local txns   = (result and result.transactions) or {}
    Format.print_index(txns)
end

local function cmd_open(services, selector)
    local path = resolve_ledger_path(services)
    if not path then return end

    if not selector or selector == "" then
        io.stderr:write("missing selector\n")
        return
    end

    local index = Ledger.read_all({ ledger_path = path })
    local txns  = (index and index.transactions) or {}

    local txn_id = selector
    local idx = tonumber(selector)
    if idx and txns[idx] then txn_id = txns[idx].transaction_id end

    local bundle = Ledger.read_bundle(txn_id, { ledger_path = path })
    if not bundle then
        io.stderr:write("bundle not found\n")
        return
    end

    local entry  = bundle.entry or {}
    local order  = bundle.order or {}
    local boards = bundle.boards or {}

    print("")
    print("=== TRANSACTION ===")
    print("txn_id:", entry.transaction_id)
    print("date:", entry.date)
    print("type:", entry.type)
    print("value:", Format.money(entry.value))
    print("total_bf:", entry.total_bf or 0)

    print("")
    print("=== ORDER ===")
    print("order_number:", Format.order_number(order))
    print("client:", order.client or order.customer_name or "")
    print("claimant:", order.claimant or "")

    print("")
    print("=== BOARDS ===")
    print("count:", #boards)
end

local function cmd_ingest(services, input_path)
    local path = resolve_ledger_path(services)
    if not path then return end

    if not input_path or input_path == "" then
        io.stderr:write("missing input path\n")
        return
    end

    local runtime = Runtime.load(input_path, { category = "order" })
    local result  = Ledger.commit(runtime, { ledger_path = path })

    print("ingested:", #(result.transactions or {}))
end

local function cmd_browser(services)
    local path = resolve_ledger_path(services)
    if not path then return end

    local index = Ledger.read_all({ ledger_path = path })
    local txns  = (index and index.transactions) or {}

    -- Browser should obey global terminal rules
    return Browser.run({
        term = Term,
        services = services,
        open = function(txn_id)
            cmd_open(services, txn_id)
        end
    }, path, txns)
end

function DOMAIN.menu(services)
    return Menu.new({
        title = "Ledger",
        prompt = "ledger> ",
        help = help_text,
        on_line = function(_ctx, line)
            if line == "back" then return "__back" end

            local cmd, rest = line:match("^(%S+)%s*(.*)$")
            rest = rest or ""

            if cmd == "set" then
                return cmd_set(services, rest)
            elseif cmd == "show" then
                return cmd_show(services)
            elseif cmd == "inspect" or cmd == "list" then
                return cmd_inspect(services)
            elseif cmd == "open" then
                return cmd_open(services, rest)
            elseif cmd == "ingest" then
                return cmd_ingest(services, rest)
            elseif cmd == "browser" then
                return cmd_browser(services)
            else
                print("unknown ledger command. try: help")
            end
        end
    })
end

return DOMAIN
