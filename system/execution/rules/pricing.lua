-- system/execution/rules/pricing.lua
-- function: PricingRules.plan
--
-- Determines execution order for pricing service.
--
-- Rules:
--
-- 1. If opts.force == true
--        → pricing
--
-- 2. If pricing fields missing
--        → pricing
--
-- 3. If pricing fields already populated
--        → (no execution)

local PricingRules = {}

local Schema = require("core.schema")

------------------------------------------------
-- Helpers
------------------------------------------------

local PRICE_FIELDS = {
    "bf_price",
    "ea_price",
    "lf_price",
}

local function board_price_fields_present(board)

    if type(board) ~= "table" then
        return false
    end

    local missing =
        Schema.object.missing("board", board)

    local missing_set = {}

    for _, field_name in ipairs(missing or {}) do
        missing_set[field_name] = true
    end

    for _, field_name in ipairs(PRICE_FIELDS) do
        if missing_set[field_name] then
            return false
        end
    end

    return true
end


local function board_price_fields_populated(board)

    if not board_price_fields_present(board) then
        return false
    end

    if type(board.bf_price) ~= "number" or board.bf_price <= 0 then
        return false
    end

    if type(board.ea_price) ~= "number" or board.ea_price <= 0 then
        return false
    end

    if type(board.lf_price) ~= "number" or board.lf_price <= 0 then
        return false
    end

    return true
end


local function batch_pricing_ready(batch)

    local boards = batch and batch.boards

    if type(boards) ~= "table" or #boards == 0 then
        return false
    end

    for _, board in ipairs(boards) do
        if not board_price_fields_populated(board) then
            return false
        end
    end

    return true
end

------------------------------------------------
-- Planner
------------------------------------------------

---@param ctx table
---@return table
function PricingRules.plan(ctx)

    local batch =
        ctx.target

    local opts =
        ctx.opts or {}

    local force =
        opts.force == true

    local pricing_ready =
        batch_pricing_ready(batch)

    ------------------------------------------------
    -- forced execution
    ------------------------------------------------

    if force then
        return { "pricing" }
    end

    ------------------------------------------------
    -- run only if pricing missing
    ------------------------------------------------

    if not pricing_ready then
        return { "pricing" }
    end

    ------------------------------------------------
    -- pricing already exists
    ------------------------------------------------

    return {}
end

return PricingRules
