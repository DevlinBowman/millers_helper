print('running main.lua')
local I           = require("inspector")
local Trace       = require("tools.trace.trace")
local Diagnostic  = require("tools.diagnostic")
local ConsoleSink = require("tools.diagnostic.sinks.console")

local Load = require("core.domain.runtime.controller")

local Persistence = require("system.app.persistence")
local Backend     = require("system.backend")
local CompareSvc  = require("system.services.compare_service")

-- load state from disk
local state = Persistence.load()

-- configure loadables
state:set_loadable("order", "/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input.txt")
state:set_loadable("vendor", "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/home_depot.txt")

-- execute request
local out = Backend.execute(state, CompareSvc, {})

if not out.ok then
  print("ERROR:", out.error)
else
  for _, line in ipairs((out.result.result or {}).lines or {}) do
    print(line)
  end
end

-- persist for next session
Persistence.save(state)
