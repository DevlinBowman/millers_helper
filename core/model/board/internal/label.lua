-- core/model/board/internal/label.lua
--
-- Board label compatibility wrapper.
--
-- Label grammar and parsing are owned by core.identity.
-- This module simply exposes the model-facing interface.

local ID = require("core.identity")

local Label = {}

------------------------------------------------
-- generate
------------------------------------------------

---Generate canonical board label from spec.
---@param spec table
---@return string
function Label.generate(spec)
    print(ID.board.label(spec):full())

    return ID.board.label(spec):full()
end

------------------------------------------------
-- hydrate
------------------------------------------------

---Parse board label into specification table.
---@param label string
---@return table
function Label.hydrate(label)
    return ID.board.parse(label)
end

return Label
