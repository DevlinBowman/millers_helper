-- core/identity/board/schema.lua
--
-- Board schema helpers used by identity.

local S = require("core.schema")

local BoardSchema = {}

------------------------------------------------
-- classification fields
------------------------------------------------

function BoardSchema.classification_fields()

    local fields = S.schema.fields("board")

    local result = {}

    for _,name in ipairs(fields) do

        local f = S.schema.field("board", name)

        if f and f.type == "symbol" then
            result[#result+1] = name
        end

    end

    return result
end

return BoardSchema
