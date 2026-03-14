local Formula = require("core.formula").board

local PricingProjector = {}

---@param target table
---@param service_result table
---@return table|nil
function PricingProjector.materialize(target, service_result)

    local domain_result = service_result.result

    if not domain_result then
        return nil
    end

    local model = domain_result:model()
    local raw = model:raw()
    local per_board = raw.per_board or {}
    local boards = target.boards or {}
    local index_map = target.board_indices or {}

    local patch = {
        capability = "board_prices",
        changes = {
            boards = {}
        }
    }

    for scoped_pos = 1, #boards do

        local original_index = index_map[scoped_pos] or scoped_pos
        local row = per_board[scoped_pos]
        local board = boards[scoped_pos]
        if row and board then

            local bf_price = row.recommended_price_per_bf

            if type(bf_price) == "number" then

                local f = Formula(board)
                local ea_price = f:bf_to_ea(bf_price)
                local lf_price = f:bf_to_lf(bf_price)
                local batch_price = f:ea_to_batch(ea_price)

                patch.changes.boards[original_index] = {
                    bf_price    = bf_price,
                    ea_price    = ea_price,
                    lf_price    = lf_price,
                    batch_price = batch_price,
                }

            end
        end
    end

    if next(patch.changes.boards) == nil then
        return nil
    end

    return patch
end

return PricingProjector
