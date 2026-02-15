-- core/model/board/registry.lua
--
-- Internal capability index for the board model.
-- No orchestration. No tracing. No contracts.

local Registry = {}

Registry.schema          = require("core.model.board.internal.schema")
Registry.coerce          = require("core.model.board.internal.coerce")
Registry.validate        = require("core.model.board.internal.validate")
Registry.derive          = require("core.model.board.internal.derive")
Registry.identity        = require("core.model.board.internal.identity")

Registry.normalize       = require("core.model.board.internal.normalize")
Registry.attr_conversion = require("core.model.board.internal.attr_conversion")
Registry.utils           = require("core.model.board.internal.utils.helpers")

Registry.label           = require("core.model.board.internal.label.init")

return Registry
