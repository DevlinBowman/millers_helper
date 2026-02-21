-- interface/tui/services.lua

local Store = require("interface.state.store")

local Services = {}

function Services.build(opts)
    opts = opts or {}

    local state = Store.new({
        path = opts.state_path or (os.getenv("HOME") .. "/.lumber_app_state.lua"),
    })

    return {
        state = state,
        -- add more shared services here later (logger, confirm, etc.)
    }
end

return Services
