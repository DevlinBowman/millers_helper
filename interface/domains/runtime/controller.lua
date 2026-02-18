-- interface/domains/runtime/controller.lua

local RuntimeAPI = require("app.api.runtime")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({}, Controller)
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function list_batches(batches)
    for i, bundle in ipairs(batches) do
        local order = bundle.order or {}
        local id = order.order_number or order.id or ("batch_" .. i)

        print(string.format(
            "%02d | boards: %-3d | id: %s",
            i,
            #(bundle.boards or {}),
            tostring(id)
        ))
    end
end

----------------------------------------------------------------
-- Runtime Load
----------------------------------------------------------------

function Controller:load(ctx)
    if #ctx.positionals < 1 then
        return ctx:usage()
    end

    local input_path = ctx.positionals[1]

    local result = RuntimeAPI.load(input_path)
    local batches = result.batches or {}

    local count = #batches

    print("batches: " .. tostring(count))

    ------------------------------------------------------------
    -- Single batch → safe
    ------------------------------------------------------------

    if count == 1 then
        return batches[1]
    end

    ------------------------------------------------------------
    -- Multiple batches
    ------------------------------------------------------------

    print("multiple orders detected")

    local flag_index = ctx.flags.index
    local flag_list  = ctx.flags.list
    local flag_all   = ctx.flags.all

    if flag_list then
        list_batches(batches)
        return
    end

    if flag_index then
        local idx = tonumber(flag_index)
        if not idx or not batches[idx] then
            ctx:die("invalid index")
        end
        return batches[idx]
    end

    if flag_all then
        return batches
    end

    ------------------------------------------------------------
    -- No selection provided
    ------------------------------------------------------------

    print("use one of:")
    print("  --list           list available orders")
    print("  --index <n>      select order")
    print("  --all            operate on all")

    return
end

return Controller
