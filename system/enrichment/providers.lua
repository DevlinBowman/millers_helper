-- system/enrichment/providers.lua

local Providers = {}

------------------------------------------------------------
-- board_prices provider
------------------------------------------------------------

Providers.board_prices = function(app, selector, env)

    local Interpreter = require("system.app.intent.interpreter")

    local runtime = app:data():runtime()
    local intent  = app:data():intent():all()

    local ctx = Interpreter.build("pricing", runtime, intent) or {}
    local opts = {}

    for key, value in pairs(env.opts or {}) do
        opts[key] = value
    end

    for key, value in pairs(ctx) do
        opts[key] = value
    end

    return app:services():pricing():resolve(selector, opts)
end

------------------------------------------------------------
-- vendor_prices provider
------------------------------------------------------------

Providers.vendor_prices = function(_, _, env)
    local vendors = env.vendors or {}

    for _, batch in ipairs(vendors) do
        for _, board in ipairs(batch.boards or {}) do
            if type(board.bf_price) == "number" and board.bf_price > 0 then
                return {
                    ok = true,
                    capability = "vendor_prices"
                }
            end
        end
    end

    return nil
end

return Providers
