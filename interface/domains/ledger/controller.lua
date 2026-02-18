local API = require("app.api.ledger")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({}, Controller)
end

function Controller:inspect(ctx)
    if #ctx.positionals < 1 then
        return ctx:usage()
    end

    local ledger_path = ctx.positionals[1]

    local result = API.inspect({
        ledger_path = ledger_path
    })

    print("transactions: " .. tostring(#result.transactions))
end

function Controller:ingest(ctx)
    if #ctx.positionals < 2 then
        return ctx:usage()
    end

    local ledger_path = ctx.positionals[1]
    local input_path  = ctx.positionals[2]

    local result = API.ingest({
        ledger_path = ledger_path,
        input_path  = input_path
    })

    print("ingested: " .. tostring(#result.transactions))
end

function Controller:browse(ctx)
    if #ctx.positionals < 1 then
        return ctx:usage()
    end

    local ledger_path = ctx.positionals[1]

    local result = API.inspect({
        ledger_path = ledger_path
    })

    for i, txn in ipairs(result.transactions) do
        print(string.format(
            "%02d | %s | %s | %s",
            i,
            txn.transaction_id,
            txn.date,
            txn.type
        ))
    end
end

return Controller
