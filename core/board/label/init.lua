-- core/board/label/init.lua
--
-- Public label API.
-- Replaces legacy core/board/label.lua.

local Generate = require("core.board.label.generate")
local Hydrate  = require("core.board.label.hydrate")

local Label = {}

Label.generate = Generate.from_spec
Label.hydrate  = Hydrate.to_spec

return Label
