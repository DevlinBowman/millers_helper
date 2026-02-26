-- main.lua
local I       = require('inspector')

-- local Context = require("system.infrastructure.context")
-- local Query   = require('platform.io.query').controller
--
-- Context.init("default")
--
-- local Runtime      = require('core.domain.runtime.controller')
-- local Select       = require('platform.selector').controller
-- local Persist      = require("platform.persist").controller
-- local AppFS        = require('system.infrastructure.application_file_store')
-- local FS           = require('platform.io.helpers.fs')
-- local PushVendor   = require('core.domain.vendor_reference').controller
--
-- -- local target_path = "/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/"
-- -- local listing     = Query.query(target_path):files()[1]
-- --
-- -- I.print(listing)
-- local user         = Runtime.load("/Users/ven/Desktop/2026-lumber-app-v3/data/test_inputs/input_short.txt")
-- local vendor       = Runtime.load("/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/home_depot.txt")
-- local vendor2      = Runtime.load("/Users/ven/Desktop/2026-lumber-app-v3/data/ref/retailer_lumber/ace_ben_lomond.txt")
-- local vendor2_cache= "/Users/ven/Desktop/2026-lumber-app-v3/data/app/default/system/caches/vendor/ace_hardware.csv"
--
--
-- -- I.print(vendor2)
--
-- local result = PushVendor.update('ace_ben_lomond', vendor2:batch())
-- I.print(result:package():rows())
-- result:require_no_errors()
--
-- result:package():write_strict(vendor2_cache, "delimited")

local Backend = require("system.backend")

local app = Backend.run("default")

-- Access canonical locations
local vendor_files = app:vendor_store():files()
local vendor_path  = app:vendor_store():path()

-- Inspect filesystem state
local fs_map = app:fs():inspect_fs()

-- Inspect logical graph
local graph = app:inspect_graph()
I.print(app:fs():vendor_store():files())
-- I.print(graph)
local a = app:vendor_store():files()
-- I.print(app:inspect_graph())
I.print(app:fs():user_inputs():path())
I.print(app:vendor_store():files())
