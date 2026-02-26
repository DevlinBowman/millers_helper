local Surface = require("system.app.surface")
local s = Surface.new()

print(type(s.run_compare))           -- should be "function"
print(type(s.vendor_reference))      -- should be "function"
print(type(s.status))                -- should be "function
