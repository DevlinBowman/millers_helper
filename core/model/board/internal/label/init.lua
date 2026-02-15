-- core/model/board/label/init.lua

local Generate = require("core.model.board.internal.label.generate")
local Hydrate  = require("core.model.board.internal.label.hydrate")

local Label = {}

Label.generate = Generate.from_spec
Label.hydrate  = Hydrate.to_spec

return Label
