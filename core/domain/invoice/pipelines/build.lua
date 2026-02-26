local DocBuild = require("core.domain._priced_doc.build")

local Build = {}

local function enforce_prices(boards)
    for _, board in ipairs(boards or {}) do
        if board.bf_price == nil then
            error(
                "Invoice requires priced boards: " ..
                tostring(board.id or board.label or "?"),
                2
            )
        end
    end
end

function Build.run(args)
    assert(type(args) == "table", "invoice.build requires args table")
    assert(type(args.boards) == "table", "invoice.build requires boards")
    assert(type(args.order) == "table", "invoice.build requires order")

    enforce_prices(args.boards)

    return DocBuild.run({
        id     = args.id,  -- optional
        boards = args.boards,
        header = {
            document_type  = "INVOICE",
            order_number   = args.order.order_number,
            client         = args.order.client,
            claimant       = args.order.claimant,
            date           = args.order.date,
            status         = args.order.order_status,
            use            = args.order.use,
            transaction_id = args.transaction_id,
        }
    })
end

return Build
