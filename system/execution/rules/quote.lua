-- system/execution/rules/quote.lua
-- function: QuoteRules.plan
--
-- Determines execution order for quote service.
--
-- Rules:
--
-- 1. If pricing.force == true
--        → pricing → quote
--
-- 2. If no board prices AND pricing intent exists
--        → pricing → quote
--
-- 3. If no board prices AND no pricing intent
--        → quote
--
-- 4. If board prices already exist
--        → quote

local QuoteRules = {}

local function boards_have_prices(batch)

    local boards = batch and batch.boards

    if type(boards) ~= "table" then
        return false
    end

    for _, board in ipairs(boards) do
        if type(board.bf_price) ~= "number" then
            return false
        end
    end

    return true
end


---@param ctx table
---@return table
function QuoteRules.plan(ctx)

    local plan = {}

    local batch =
        ctx.target

    local intent =
        ctx.intent

    local opts =
        ctx.opts or {}

    local force =
        opts.force == true

    local pricing_intent =
        intent and intent.get and intent:get("pricing")

    local has_prices =
        boards_have_prices(batch)

    ------------------------------------------------
    -- rule 1: forced pricing
    ------------------------------------------------

    if force then
        plan[#plan+1] = "pricing"
        plan[#plan+1] = "quote"
        return plan
    end

    ------------------------------------------------
    -- rule 2: prices missing but pricing allowed
    ------------------------------------------------

    if not has_prices and pricing_intent then
        plan[#plan+1] = "pricing"
        plan[#plan+1] = "quote"
        return plan
    end

    ------------------------------------------------
    -- rule 3 + 4
    ------------------------------------------------

    plan[#plan+1] = "quote"

    return plan
end

return QuoteRules
