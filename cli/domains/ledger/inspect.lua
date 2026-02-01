-- cli/domains/ledger/inspect.lua

local I        = require("inspector")
local Ledger   = require("ledger")
local Store    = Ledger.store
local Summary  = require("ledger.analysis.summary")
local Keys     = require("ledger.analysis.keys")
local Describe = require("ledger.analysis.describe")

local M = {}

M.help = {
    summary = "Inspect ledger contents",
    usage   = "ledger inspect <ledger> [options]",
    options = {
        { "-k, --keys",        "Show board and ledger key surface" },
        { "-d, --describe",    "Describe all fields or a single field" },
        { "    --describe <f>","Describe a specific field" },
    },
    examples = {
        "ledger inspect data/ledger.lua",
        "ledger inspect data/ledger.lua --keys",
        "ledger inspect data/ledger.lua --describe bf_price",
    },
}

function M.run(ctx)
    local ledger_path = ctx.positionals[1]
    if not ledger_path then
        ctx:die("ledger inspect <ledger>")
    end

    local ledger = Store.load(ledger_path)

    if ctx.flags.keys or ctx.flags.k then
        I.print(Keys.run(ledger))
        return
    end

    if ctx.flags.describe or ctx.flags.d then
        local field = ctx.positionals[2]
        if field then
            local info = Describe.field(field)
            if not info then
                ctx:die("unknown field: " .. tostring(field))
            end
            I.print(info)
        else
            I.print(Describe.all())
        end
        return
    end

    I.print(Summary.run(ledger))
end

return M
