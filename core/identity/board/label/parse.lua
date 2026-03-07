local Helpers = require("core.identity.board.helpers")
local Schema  = require("core.identity.schema")

local Parse = {}

local BoardSchema = require("core.identity.board.schema")
local COMMERCIAL_ORDER = BoardSchema.classification_fields()

function Parse.run(label)

    assert(type(label) == "string", "label must be string")

    local tokens = Helpers.tokenize(label)
    assert(#tokens >= 1, "invalid label")

    local spec = Helpers.parse_dimension(tokens[1])

    local index = 1

    for i = 2, #tokens do

        local tok = tokens[i]

        if Helpers.is_count(tok) then

            spec.ct = tonumber(tok:sub(2))

        elseif Schema.is_value("board.surface", tok) then

            spec.surface = tok

        elseif Schema.is_value("board.species", tok)
            or Schema.is_value("board.grade", tok)
            or Schema.is_value("board.moisture", tok)
        then

            local key = COMMERCIAL_ORDER[index]

            if not key then
                error("too many commercial tokens in label: "..label)
            end

            spec[key] = tok
            index = index + 1

        else
            error("unrecognized label token: "..tok)
        end

    end

    return spec
end

return Parse
