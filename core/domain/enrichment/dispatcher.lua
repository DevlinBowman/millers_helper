local Pricing = require("core.domain.pricing").controller
local Board   = require("core.model.board").controller

local Dispatcher = {}

local function collect_pricing_targets(requests)

    local boards = {}

    for _,r in ipairs(requests) do
        if r.service == "pricing" then

            local path = r.path

            if path[1] == "boards" and type(path[2]) == "number" then
                boards[path[2]] = true
            end

        end
    end

    return boards
end

function Dispatcher.execute(batch, requests, opts)

    opts = opts or {}

    ------------------------------------------------
    -- collect pricing targets
    ------------------------------------------------

    local pricing_targets =
        collect_pricing_targets(requests)

    if not next(pricing_targets) then
        return
    end

    ------------------------------------------------
    -- run pricing engine
    ------------------------------------------------

    local result =
        Pricing.run(
            batch.boards,
            opts.basis or "vendor_anchor",
            opts
        )

    local model = result:model():raw()

    ------------------------------------------------
    -- apply mutations
    ------------------------------------------------

    for index,_ in pairs(pricing_targets) do

        local board = batch.boards[index]
        local row   = model.per_board[index]

        if board and row then

            Board.mutate(board,{
                bf_price = row.recommended_price_per_bf
            })

        end

    end

end

return Dispatcher
