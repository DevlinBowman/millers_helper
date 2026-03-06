-- core/domain/enrichment/services/pricing.lua

local Pricing = require("core.domain.pricing").controller

local Service = {}

local function collect_target_indexes(task)
    local indexes = {}

    for _, target in ipairs(task.targets or {}) do
        local path = target.path

        if path and path[1] == "boards" and type(path[2]) == "number" then
            indexes[path[2]] = true
        end
    end

    return indexes
end

-- core/domain/enrichment/services/pricing.lua
-- function: Service.resolve

function Service.resolve(batch, task, opts)
    opts = opts or {}

    local target_indexes = collect_target_indexes(task)

    if not next(target_indexes) then
        return nil
    end

    local basis =
        opts.pricing_basis
        or opts.basis

    if not basis then
        local order = batch.order

        if order
            and order.use == "sale"
            and type(order.value) == "number"
            and order.value > 0
        then
            basis = "reverse_order_value"
            opts.target_total_value = order.value
        else
            basis = "vendor_anchor"
        end
    end

    local result =
        Pricing.run(batch, basis, opts)

    local model = result:model():raw()

    local patch = {
        service = "pricing",
        changes = {
            boards = {}
        }
    }

    for index in pairs(target_indexes) do
        local row = model.per_board and model.per_board[index]

        if row and row.recommended_price_per_bf ~= nil then
            patch.changes.boards[index] = {
                bf_price = row.recommended_price_per_bf
            }
        end
    end

    if next(patch.changes.boards) == nil then
        return nil
    end

    return patch
end

return Service
