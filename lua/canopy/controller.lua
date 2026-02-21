-- canopy/controller.lua

local App = require("canopy.runtime.app")

local Controller = {}

-- Construct only
function Controller.new(opts)
    return App.new(opts)
end

-- Construct + run
function Controller.open(opts)
    local app = App.new(opts)
    app:run()
    return app
end

return Controller
