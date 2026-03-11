-- system/capability/materializers/pricing.lua

local PricingMaterializer = {}

local function as_number(value)
    if type(value) == "number" then
        return value
    end
    return nil
end

local function resolve_quantity(board)
    return as_number(board.qty)
        or as_number(board.quantity)
        or as_number(board.count)
        or 1
end

local function resolve_length_feet(board)
    return as_number(board.l)
        or as_number(board.length)
        or as_number(board.length_ft)
        or as_number(board.feet)
end

local function resolve_board_feet(board)
    local direct =
        as_number(board.bf)
        or as_number(board.board_feet)
        or as_number(board.boardfeet)

    if direct and direct > 0 then
        return direct
    end

    local height_in =
        as_number(board.h)
        or as_number(board.height)
        or as_number(board.base_h)

    local width_in =
        as_number(board.w)
        or as_number(board.width)
        or as_number(board.base_w)

    local length_ft = resolve_length_feet(board)

    if height_in and width_in and length_ft then
        return (height_in * width_in * length_ft) / 12
    end

    return nil
end

---@param target table
---@param service_result table
---@param capability string
---@return table|nil
function PricingMaterializer.materialize(target, service_result, capability)
    assert(type(target) == "table", "[pricing.materializer] target required")
    assert(type(service_result) == "table", "[pricing.materializer] service_result required")

    local domain_result = service_result.result
    if not domain_result then
        return nil
    end

    assert(type(domain_result.model) == "function",
        "[pricing.materializer] pricing result missing model()")

    local model = domain_result:model()
    assert(type(model) == "table" and type(model.raw) == "function",
        "[pricing.materializer] pricing result model missing raw()")

    local raw_model = model:raw()
    local per_board = raw_model.per_board or {}

    local patch = {
        capability = "board_prices",
        changes = {
            boards = {}
        }
    }

    for board_index, row in ipairs(per_board) do
        local target_board = target.boards and target.boards[board_index]
        local recommended_price_per_bf =
            row and row.recommended_price_per_bf

        if target_board and type(recommended_price_per_bf) == "number" then
            local unit_board_feet = resolve_board_feet(target_board)
            local length_feet = resolve_length_feet(target_board)
            local quantity = resolve_quantity(target_board)

            local each_price =
                unit_board_feet and (recommended_price_per_bf * unit_board_feet) or nil

            local lineal_foot_price =
                (each_price and length_feet and length_feet > 0)
                and (each_price / length_feet)
                or nil

            local batch_price =
                (each_price and quantity)
                and (each_price * quantity)
                or nil

            patch.changes.boards[board_index] = {
                bf_price    = recommended_price_per_bf,
                ea_price    = each_price,
                lf_price    = lineal_foot_price,
                batch_price = batch_price,
            }
        end
    end

    if next(patch.changes.boards) == nil then
        return nil
    end

    return patch
end

return PricingMaterializer
