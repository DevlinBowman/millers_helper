-- system/compatibility/validator.lua
-- function: Validator.validate

local Validator = {}

local function append_unique(out, seen, name)
    if not seen[name] then
        seen[name] = true
        out[#out + 1] = name
    end
end

------------------------------------------------
-- capability resolver
------------------------------------------------

local function capability_present(name, env, contract)

    -- simple env field
    if env[name] ~= nil then
        return true
    end

    -- dotted path support
    if name:find("%.") then

        local node = env

        for part in name:gmatch("[^%.]+") do
            if type(node) ~= "table" then
                node = nil
                break
            end
            node = node[part]
        end

        if node ~= nil then
            return true
        end
    end

    ------------------------------------------------
    -- contract capability function
    ------------------------------------------------

    if contract
        and contract.capabilities
        and type(contract.capabilities[name]) == "function" then

        local ok, result =
            pcall(contract.capabilities[name], env)

        if ok and result == true then
            return true
        end
    end

    return false
end

------------------------------------------------
-- optional contract env builder
------------------------------------------------

local function build_contract_env(contract, strategy, env)

    if not contract or type(contract.build_env) ~= "function" then
        return env
    end

    ------------------------------------------------
    -- attempt to translate execution env → contract env
    ------------------------------------------------

    local source
    local opts

    if type(env) == "table" then

        if env.source then
            source = env.source
        elseif env.job and type(env.job.batch) == "function" then
            source = env.job:batch()
        end

        opts = env.opts
    end

    local ok, built =
        pcall(contract.build_env, source, strategy, opts)

    if ok and type(built) == "table" then
        return built
    end

    return env
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

    if contract[strategy] then

        strat = contract[strategy]

    elseif contract.strategies and contract.strategies[strategy] then

        strat = contract.strategies[strategy]

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

    ------------------------------------------------
    -- normalize env if contract provides builder
    ------------------------------------------------

    env = build_contract_env(contract, strategy, env)

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

        if not capability_present(name, env, contract) then
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
