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

    strategy = strategy or "default"

    local strat =
        (contract.strategies or {})[strategy]

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
    -- base requirements
    ------------------------------------------------

    for _, name in ipairs((contract.base and contract.base.required) or {}) do

        if not capability_present(name, env) then
            append_unique(missing, seen, name)
        end

    end

    ------------------------------------------------
    -- strategy requirements
    ------------------------------------------------

    for _, name in ipairs(strat.required or {}) do

        if not capability_present(name, env) then
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
