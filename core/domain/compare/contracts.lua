-- core/domain/compare/contracts.lua
--
-- Compare service contract authority.

local Contracts = {}

------------------------------------------------------------
-- Context Builder
------------------------------------------------------------
---@param user_batch table
---@param vendor_batches table
---@param opts table|nil
---@return table
function Contracts.build_env(user_batch, vendor_batches, opts)
    return {
        source  = user_batch,
        job     = user_batch,
        vendors = vendor_batches or {},
        opts    = opts or {},
    }
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function board_has_price(board)
    if type(board) ~= "table" then
        return false
    end

    if type(board.bf_price) == "number" and board.bf_price > 0 then
        return true
    end

    if type(board.ea_price) == "number"
        and board.ea_price > 0
        and type(board.bf_ea) == "number"
        and board.bf_ea > 0
    then
        return true
    end

    return false
end

------------------------------------------------------------
-- Capability Checks
------------------------------------------------------------

Contracts.capabilities = {}

---@param env table
---@return boolean
function Contracts.capabilities.job(env)
    return type(env) == "table"
        and type(env.job) == "table"
        and type(env.job.boards) == "table"
end

---@param env table
---@return boolean
function Contracts.capabilities.vendors(env)
    return type(env) == "table"
        and type(env.vendors) == "table"
        and #env.vendors > 0
end

---@param env table
---@return boolean
function Contracts.capabilities.board_prices(env)
    if not Contracts.capabilities.job(env) then
        return false
    end

    for _, board in ipairs(env.job.boards) do
        if not board_has_price(board) then
            return false
        end
    end

    return true
end

---@param env table
---@return boolean
function Contracts.capabilities.vendor_prices(env)
    if not Contracts.capabilities.vendors(env) then
        return false
    end

    for _, batch in ipairs(env.vendors) do
        local boards = batch and batch.boards or {}

        for _, board in ipairs(boards) do
            if board_has_price(board) then
                return true
            end
        end
    end

    return false
end

------------------------------------------------------------
-- Contract Shape
------------------------------------------------------------

Contracts.base = {
    required = {
        "job",
        "vendors",
        "board_prices",
        "vendor_prices",
    },

    optional = {}
}

Contracts.strategies = {
    default = {
        required = {},
        optional = {},
        opts = {}
    }
}

return Contracts
