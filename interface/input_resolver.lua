-- interface/input_resolver.lua
--
-- Universal runtime input resolution.
-- Every domain may call this.

local Runtime = require("core.domain.runtime.controller")

local Resolver = {}

---@param ctx table
---@return RuntimeView|nil
function Resolver.resolve(ctx)

    ------------------------------------------------------------
    -- Ledger source
    ------------------------------------------------------------
    if ctx.flags.ledger then
        return Runtime.load({
            ledger_path = ctx.flags.ledger
        }, {
            category = "ledger"
        })
    end

    ------------------------------------------------------------
    -- Explicit order + boards
    ------------------------------------------------------------
    if ctx.flags.order and ctx.flags.boards then

        local order_runtime = Runtime.load(
            ctx.flags.order,
            { category = "order" }
        )

        local boards_runtime = Runtime.load(
            ctx.flags.boards,
            { category = "boards" }
        )

        return Runtime.associate(order_runtime, boards_runtime)
    end

    ------------------------------------------------------------
    -- Positional single input
    ------------------------------------------------------------
    if #ctx.positionals >= 1 then
        return Runtime.load(ctx.positionals[1])
    end

    return nil
end

return Resolver
