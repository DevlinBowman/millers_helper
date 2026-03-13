-- system/execution/rules/compare.lua
-- function: CompareRules.plan

local CompareRules = {}

------------------------------------------------
-- Helpers
------------------------------------------------

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

------------------------------------------------
-- Planner
------------------------------------------------

---@param ctx table
---@return table
function CompareRules.plan(ctx)

    local plan = {}

    local batch = ctx.target
    local intent = ctx.intent
    local opts = ctx.opts or {}
    local force = opts.force == true
    local pricing_intent = intent and intent.get and intent:get("pricing")
    local has_prices = boards_have_prices(batch)

    ------------------------------------------------
    -- pricing rules
    ------------------------------------------------

    if force then
        plan[#plan+1] = "pricing"
    elseif not has_prices and pricing_intent then
        plan[#plan+1] = "pricing"
    end

    ------------------------------------------------
    -- compare always runs
    ------------------------------------------------

    plan[#plan+1] = "compare"

    return plan
end

return CompareRules
