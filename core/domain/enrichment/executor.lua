-- core/domain/enrichment/executor.lua

local Pricing = require("core.domain.pricing").controller
local Board   = require("core.model.board").controller

local Executor = {}

function Executor.run(batch, tasks, opts)

    opts = opts or {}

    for _,task in ipairs(tasks) do

        ------------------------------------------------
        -- pricing
        ------------------------------------------------

        if task.service == "pricing" then

            local result =
                Pricing.run(
                    batch.boards,
                    opts.basis or "vendor_anchor",
                    opts
                )

            local model = result:model():raw()

            for _,index in ipairs(task.boards) do

                local board = batch.boards[index]
                local row   = model.per_board[index]

                if board and row then

                    Board.mutate(board,{
                        bf_price = row.recommended_price_per_bf
                    })

                end

            end

        end

        ------------------------------------------------
        -- allocations (stub for now)
        ------------------------------------------------

        if task.service == "allocations" then

            batch.allocations = batch.allocations or {}

        end

    end

end

return Executor
