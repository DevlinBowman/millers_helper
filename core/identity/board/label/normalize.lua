local Parse = require("core.identity.board.label.parse")
local Context = require("core.identity.board.context")

local Normalize = {}

------------------------------------------------
-- normalize label
------------------------------------------------

function Normalize.run(label)

    local spec = Parse.run(label)

    return Context.new(spec):full()

end

return Normalize
