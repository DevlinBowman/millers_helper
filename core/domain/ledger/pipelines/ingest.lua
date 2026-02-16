local IO          = require("io.controller")
local Build       = require("core.domain.ledger.internal.build")
local Storage     = require("core.domain.ledger.internal.storage")
local Ledger      = require("core.domain.ledger.internal.ledger")
local Attachments = require("core.domain.ledger.internal.attachments")
local Identity    = require("core.domain.ledger.internal.identity")

local Ingest = {}

function Ingest.from_path(path, opts)
    opts = opts or {}

    local result = IO.read_strict(path)

    local transaction_id =
        opts.transaction_id or Identity.generate()

    local entry = Build.run(
        vim.tbl_extend("force", result.data, {
            transaction_id = transaction_id
        })
    )

    Storage.write_entry(entry)

    if opts.attach_source ~= false then
        Attachments.add(transaction_id, path)
    end

    Ledger.append(entry)

    return entry
end

return Ingest
