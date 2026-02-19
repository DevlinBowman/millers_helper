local Runtime  = require("core.domain.runtime.controller")
local Ledger   = require("core.domain.ledger.controller")

local Path     = require("interface.domains.ledger.path")
local Format   = require("interface.domains.ledger.format")
local Browser  = require("interface.domains.ledger.browser")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({}, Controller)
end

------------------------------------------------------------
-- Set Ledger Path
------------------------------------------------------------

function Controller:ledger(ctx)

    local path = ctx.positionals[1]

    if not path then
        local Session = require("interface.session")
        local current = Session.get_ledger_path()

        if current then
            print("current ledger:", current)
        else
            print("no ledger set")
        end
        return
    end

    local Session = require("interface.session")
    Session.set_ledger_path(path)
    print("ledger set:", path)
end

------------------------------------------------------------
-- Inspect
------------------------------------------------------------

function Controller:inspect(ctx)

    local path = Path.resolve(ctx)
    if not path then return end

    local result = Ledger.read_all({ ledger_path = path })
    local txns   = (result and result.transactions) or {}

    Format.print_index(txns)

    return result
end

function Controller:browse(ctx)
    return self:inspect(ctx)
end

------------------------------------------------------------
-- Open
------------------------------------------------------------

function Controller:open(ctx)

    local path = Path.resolve(ctx)
    if not path then return end

    local selector = ctx.positionals[1]
    if not selector then
        io.stderr:write("missing selector\n")
        return
    end

    local index = Ledger.read_all({ ledger_path = path })
    local txns  = (index and index.transactions) or {}

    local txn_id = selector
    local idx = tonumber(selector)
    if idx and txns[idx] then
        txn_id = txns[idx].transaction_id
    end

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

------------------------------------------------------------
-- Ingest
------------------------------------------------------------

function Controller:ingest(ctx)

    local path = Path.resolve(ctx)
    if not path then return end

    local input_path = ctx.positionals[1]
    if not input_path then
        io.stderr:write("missing input path\n")
        return
    end

    local runtime = Runtime.load(input_path, { category = "order" })

    local result  = Ledger.commit(runtime, {
        ledger_path = path,
        force       = ctx.flags.force,
    })

    print("ingested:", #(result.transactions or {}))

    return result
end

------------------------------------------------------------
-- Browser
------------------------------------------------------------

function Controller:browser(ctx)

    local path = Path.resolve(ctx)
    if not path then return end

    local index = Ledger.read_all({ ledger_path = path })
    local txns  = (index and index.transactions) or {}

    Browser.run(self, path, txns)
end

return Controller
