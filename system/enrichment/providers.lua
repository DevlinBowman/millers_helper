-- system/enrichment/providers.lua

local Providers = {}

------------------------------------------------------------
-- board_prices provider
------------------------------------------------------------

Providers.board_prices = function(app, selector, env)

    local Interpreter =
        require("system.app.intent.interpreter")

    local runtime = app:data():runtime()
    local intent  = app:data():intent():all()

    -- build pricing context from intent
    local ctx =
        Interpreter.build("pricing", runtime, intent) or {}

    -- merge env opts + intent opts
    local opts = {}

    for k,v in pairs(env.opts or {}) do
        opts[k] = v
    end

    for k,v in pairs(ctx) do
        opts[k] = v
    end

    local result =
        app:services():pricing():resolve(selector, opts)

    if result and result.ok then
        return { patch = result.patch }
    end

    return nil
end

------------------------------------------------------------
-- vendor_prices provider
------------------------------------------------------------

Providers.vendor_prices = function(app, selector, env)
    local vendors = env.vendors or {}

    for _, batch in ipairs(vendors) do
        for _, board in ipairs(batch.boards or {}) do
            if type(board.bf_price) == "number" and board.bf_price > 0 then
                return { ok = true }
            end
        end
    end

    return nil
end

return Providers
