-- interface/domains/compare/controller.lua

local RuntimeAPI = require("app.api.runtime")
local Compare    = require("core.domain.compare")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    return setmetatable({}, Controller)
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function order_id_of(bundle, fallback)
    local order = (bundle or {}).order or {}
    return order.order_number or order.id or fallback
end

local function list_batches(label, batches)
    print(label .. ": " .. tostring(#batches))
    for i, bundle in ipairs(batches) do
        local id = order_id_of(bundle, "batch_" .. tostring(i))
        local boards_n = #((bundle or {}).boards or {})
        print(string.format("%02d | boards: %-3d | id: %s", i, boards_n, tostring(id)))
    end
end

local function select_bundle(ctx, side_label, batches, index_flag_key, list_flag_key)
    local count = #batches

    if count == 0 then
        ctx:die(side_label .. ": no batches returned")
    end

    if count == 1 then
        return batches[1]
    end

    print(side_label .. ": multiple orders detected (" .. tostring(count) .. ")")

    if ctx.flags[list_flag_key] then
        list_batches(side_label, batches)
        return nil, "listed"
    end

    local idx_raw = ctx.flags[index_flag_key]
    if idx_raw ~= nil then
        local idx = tonumber(idx_raw)
        if not idx or not batches[idx] then
            ctx:die(side_label .. ": invalid " .. index_flag_key .. " " .. tostring(idx_raw))
        end
        return batches[idx]
    end

    return nil, "needs_selection"
end

local function print_usage_hints()
    print("use one of:")
    print("  --list                  list input orders")
    print("  --index <n>             select input order batch")
    print("  --vendor-list           list vendor batches")
    print("  --vendor-index <n>      select vendor batch")
    print("  --nevermind             abort")
end

local function print_skipped(model)
    local skipped = (model or {}).skipped
    if not skipped or #skipped == 0 then
        return
    end

    print("")
    print("Note: skipped unpriced order boards:")
    for _, s in ipairs(skipped) do
        print(string.format(
            "  #%d (%s)",
            s.index,
            s.label or ""
        ))
    end
    print("")
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

-- usage:
--   compare <input_path> <vendor_path>
--   compare <input_path> <vendor_path> --index N --vendor-index M
function Controller:run(ctx)

    if ctx.flags.nevermind then
        print("nevermind")
        return
    end

    if #ctx.positionals < 2 then
        return ctx:usage()
    end

    ------------------------------------------------------------
    -- Paths
    ------------------------------------------------------------

    local input_path = ctx.positionals[1]

    local vendor_paths = {}
    for i = 2, #ctx.positionals do
        vendor_paths[#vendor_paths + 1] = ctx.positionals[i]
    end

    ------------------------------------------------------------
    -- Load Input
    ------------------------------------------------------------

    local input_env  = RuntimeAPI.load(input_path)
    local input_batches = input_env.batches or {}

    local input_bundle, input_state =
        select_bundle(ctx, "input", input_batches, "index", "list")

    if input_state == "listed" then
        return
    end

    if input_bundle == nil then
        print("selection required")
        print_usage_hints()
        return
    end

    ------------------------------------------------------------
    -- Load Vendors (Multiple)
    ------------------------------------------------------------

    local sources = {}

    for _, vendor_path in ipairs(vendor_paths) do

        local vendor_env = RuntimeAPI.load(vendor_path)
        local vendor_batches = vendor_env.batches or {}

        local vendor_bundle, vendor_state =
            select_bundle(ctx, vendor_path, vendor_batches, "vendor_index", "vendor_list")

        if vendor_state == "listed" then
            return
        end

        if vendor_bundle == nil then
            print("selection required for vendor:", vendor_path)
            print_usage_hints()
            return
        end

        -- derive display name from file basename
        local name = vendor_path:match("([^/]+)$") or vendor_path
        name = name:gsub("%.%w+$", "") -- strip extension

        sources[#sources + 1] = {
            name   = name,
            boards = vendor_bundle.boards or {}
        }
    end

    ------------------------------------------------------------
    -- Execute Compare
    ------------------------------------------------------------

    local result = Compare.controller.compare(
        input_bundle,
        sources,
        {}
    )

    ------------------------------------------------------------
    -- Print Skipped Boards
    ------------------------------------------------------------

    print_skipped(result.model)

    ------------------------------------------------------------
    -- Print Output
    ------------------------------------------------------------

    local lines = ((result or {}).result or {}).lines or {}
    for _, line in ipairs(lines) do
        print(line)
    end

    return result
end

return Controller
