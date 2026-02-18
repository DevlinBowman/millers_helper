local Runtime = require("app.api.runtime")
local Ledger  = require("core.domain.ledger.controller")

local API = {}

function API.ingest(opts)

    local batches = Runtime.load(opts.input_path)

    return Ledger.from_ingest({
        data = batches
    })
end

function API.inspect(opts)

    return Ledger.read_all_full()
end

return API
