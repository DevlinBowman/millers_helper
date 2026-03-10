-- system/compatibility/validator.lua

local Validator = {}

local function append_unique(out, seen, name)
    if not seen[name] then
        seen[name] = true
        out[#out + 1] = name
    end
end

local function capability_ok(contract, capability_name, env)
    local checks = contract.capabilities or {}
    local fn = checks[capability_name]

    if type(fn) == "function" then
        return fn(env) == true
    end

    return env ~= nil and env[capability_name] ~= nil
end

---@param contract table
---@param strategy string|nil
---@param env table
---@return table
function Validator.validate(contract, strategy, env)
    assert(type(contract) == "table", "[compatibility.validator] contract required")
    assert(type(env) == "table", "[compatibility.validator] env required")

    strategy = strategy or "default"

    local strat = (contract.strategies or {})[strategy]
    if not strat then
        error("[compatibility.validator] unknown strategy: " .. tostring(strategy), 2)
    end

    local missing = {}
    local seen = {}

    for _, name in ipairs((contract.base and contract.base.required) or {}) do
        if not capability_ok(contract, name, env) then
            append_unique(missing, seen, name)
        end
    end

    for _, name in ipairs(strat.required or {}) do
        if not capability_ok(contract, name, env) then
            append_unique(missing, seen, name)
        end
    end

    return {
        ok = (#missing == 0),
        missing = missing,
        strategy = strategy,
    }
end

return Validator
