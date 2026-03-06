-- core/domain/pricing/strategies/vendor_anchor.lua

local PricingModel = require("core.model.pricing.controller")

local VendorAnchor = {}

local function round2(x)
    return math.floor((x or 0) * 100 + 0.5) / 100
end

local function safe_number(x, default)
    if type(x) == "number" then return x end
    return default
end

local function extract_vendor_price(board)
    if type(board.bf_price) == "number" then
        return board.bf_price
    end

    if type(board.ea_price) == "number"
        and type(board.bf_ea) == "number"
        and board.bf_ea > 0
    then
        return board.ea_price / board.bf_ea
    end

    return nil
end

function VendorAnchor.run(env)

    local boards_env = env.boards
    assert(type(boards_env) == "table",
        "[pricing.vendor_anchor] boards envelope required")
    assert(boards_env.kind == "boards",
        "[pricing.vendor_anchor] boards.kind must be 'boards'")

    local boards = boards_env.items
    assert(type(boards) == "table",
        "[pricing.vendor_anchor] boards.items required")

    local vendor_env = env.vendor
    assert(type(vendor_env) == "table",
        "[pricing.vendor_anchor] vendor envelope required")
    assert(vendor_env.kind == "vendor",
        "[pricing.vendor_anchor] vendor.kind must be 'vendor'")

    local vendor_items = vendor_env.items
    assert(type(vendor_items) == "table",
        "[pricing.vendor_anchor] vendor.items required")

    local vendor_meta = vendor_env.meta
    if vendor_meta ~= nil then
        assert(type(vendor_meta) == "table",
            "[pricing.vendor_anchor] vendor.meta must be table|nil")
    else
        vendor_meta = {}
    end

    local BoardEquivalence =
        require("core.model.board_equivalence.matcher")

    local opts = env.opts or {}
    local discount_pct = safe_number(opts.percentage, 0)

    local per_board = {}

    for i, board in ipairs(boards) do

        local matched, signal =
            BoardEquivalence.match(board, vendor_items)

        local retail

        if matched then
            retail = extract_vendor_price(matched)
        end

        assert(retail,
            "[pricing.vendor_anchor] vendor match missing price")

        local suggested = retail * (1 - discount_pct / 100)

        per_board[i] = {
            label = board.label,

            market = {
                source          = vendor_meta.name,
                match           = matched and (matched.label or matched.id),
                signal          = signal,
                retail_bf_price = retail,
            },

            suggested_price_per_bf   = round2(suggested),
            recommended_price_per_bf = round2(suggested),
            recommendation_mode      = "vendor_anchor",
        }
    end

    return {
        basis     = "vendor_anchor",
        per_board = per_board,
        opts      = opts,
    }
end

return VendorAnchor
