-- cli/domains/ledger/export.lua

local Ledger = require("ledger")
local Store  = Ledger.store
local Export = require("ledger.export_csv")

local M = {}

M.help = {
    summary = "Export ledger board data to CSV",
    usage   = "ledger export <ledger> <csv>",
    examples = {
        "ledger export data/ledger.lua out.csv",
    },
}

function M.run(ctx)
    local ledger_path = ctx.positionals[1]
    local out_path    = ctx.positionals[2]

    if not ledger_path or not out_path then
        ctx:die(M.help.usage)
    end

    local ledger = Store.load(ledger_path)
    local ok, err = Export.write_csv(ledger, out_path)
    if not ok then
        ctx:die(err)
    end
end

return M
