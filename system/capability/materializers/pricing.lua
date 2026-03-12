-- system/capability/materializers/pricing.lua

local Formula = require("core.formula").board

local PricingMaterializer = {}

---@param target table
---@param service_result table
---@param capability string
---@return table|nil
function PricingMaterializer.materialize(target, service_result, capability)

    assert(type(target) == "table",
        "[pricing.materializer] target required")

    assert(type(service_result) == "table",
        "[pricing.materializer] service_result required")

    local domain_result = service_result.result
    if not domain_result then
        return nil
    end

    local model = domain_result:model()

    assert(type(model) == "table" and type(model.raw) == "function",
        "[pricing.materializer] pricing result model missing raw()")

    local raw = model:raw()

    local per_board = raw.per_board or {}
    local boards    = target.boards or {}

    local board_count = #boards
    local model_count = #per_board

    assert(
        model_count == board_count,
        "[pricing.materializer] per_board row count mismatch: "
        .. tostring(model_count) .. " vs "
        .. tostring(board_count)
    )

    local patch = {
        capability = "board_prices",
        changes = {
            boards = {}
        }
    }

    for i = 1, board_count do

        local row   = per_board[i]
        local board = boards[i]

        if row and board then

            local bf_price =
                row.recommended_price_per_bf

            if type(bf_price) == "number" then

                local f = Formula(board)

                local ea_price    = f:bf_to_ea(bf_price)
                local lf_price    = f:bf_to_lf(bf_price)
                local batch_price = f:ea_to_batch(ea_price)

                patch.changes.boards[i] = {
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

return PricingMaterializer
