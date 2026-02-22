local DocBuild = require("core.domain._priced_doc.internal.build")
local ID       = require("system.infrastructure.id_store")

local Build = {}

local function enforce_prices(boards)
    for _, board in ipairs(boards) do
        if board.bf_price == nil then
            error("Invoice requires priced boards: " .. tostring(board.id or ""))
        end
    end
end

function Build.run(batch)
    enforce_prices(batch.boards)

    return DocBuild.run({
        id     = ID.new(),
        boards = batch.boards,
        header = {
            document_type  = "INVOICE",
            order_number   = batch.order.order_number,
            client         = batch.order.client,
            claimant       = batch.order.claimant,
            date           = batch.order.date,
            status         = batch.order.order_status,
            use            = batch.order.use,
            transaction_id = batch.transaction_id,
        }
    })
end

return Build
