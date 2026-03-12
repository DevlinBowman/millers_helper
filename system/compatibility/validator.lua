-- system/compatibility/validator.lua
-- function: Validator.validate

local Validator = {}

local function append_unique(out, seen, name)
    if not seen[name] then
        seen[name] = true
        out[#out + 1] = name
    end
end

local function capability_present(name, env)

    -- simple capability presence
    if env[name] ~= nil then
        return true
    end

    -- support dotted paths: "job.boards"
    if name:find("%.") then

        local node = env

        for part in name:gmatch("[^%.]+") do
            if type(node) ~= "table" then
                return false
            end
            node = node[part]
        end

        return node ~= nil
    end

    return false
end

---@param contract table
---@param strategy string|nil
---@param env table
---@return table
function Validator.validate(contract, strategy, env)

    assert(type(contract) == "table",
        "[compatibility.validator] contract required")

    assert(type(env) == "table",
        "[compatibility.validator] env required")

    ------------------------------------------------
    -- normalize strategy
    ------------------------------------------------

    strategy = strategy or "default"

    local strat

    ------------------------------------------------
    -- new contract format
    --
    -- contract = {
    --   default = { requires = {...} }
    -- }
    ------------------------------------------------

    if contract[strategy] then
        strat = contract[strategy]

    ------------------------------------------------
    -- legacy contract format
    --
    -- contract = {
    --   strategies = { ... }
    -- }
    ------------------------------------------------

    elseif contract.strategies and contract.strategies[strategy] then
        strat = contract.strategies[strategy]

    ------------------------------------------------
    -- fallback to first strategy
    ------------------------------------------------

    else
        for _, v in pairs(contract) do
            if type(v) == "table" then
                strat = v
                strategy = "default"
                break
            end
        end
    end

    if not strat then
        error(
            "[compatibility.validator] unknown strategy: "
            .. tostring(strategy),
            2
        )
    end

    local missing = {}
    local seen = {}

    ------------------------------------------------
    -- required capabilities
    ------------------------------------------------

    local required =
        strat.requires
        or strat.required
        or {}

    for _, name in ipairs(required) do

        if not capability_present(name, env) then
            append_unique(missing, seen, name)
        end

    end

    ------------------------------------------------
    -- result
    ------------------------------------------------

    return {
        ok       = (#missing == 0),
        missing  = missing,
        strategy = strategy,
    }
end

return Validator
