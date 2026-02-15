-- core/board/label/hydrate.lua
--
-- Label hydration (decode label into spec).

local Helpers = require("core.model.board.internal.label.helpers")

local Hydrate = {}

local COMMERCIAL_ORDER = { "species", "grade", "moisture" }

local function apply_commercial(spec, tok, state, label)
    local key = state.order[state.index]
    if not key then
        error("too many commercial tokens in label: " .. label)
    end
    spec[key] = tok
    state.index = state.index + 1
end

--- Parse a label string into a specification table.
---
--- @param label string
--- @return table
function Hydrate.to_spec(label)
    assert(type(label) == "string", "label must be string")

    local tokens = Helpers.tokenize(label)
    assert(#tokens >= 1, "invalid label: missing dimensions")

    -- dimensions (always first)
    local spec = Helpers.parse_dimension(tokens[1])

    local commercial_state = {
        order = COMMERCIAL_ORDER,
        index = 1,
    }

    -- remaining tokens
    for i = 2, #tokens do
        local tok = tokens[i]

        if Helpers.is_count(tok) then
            spec.ct = tonumber(tok:sub(2))

        elseif Helpers.is_surface(tok) then
            spec.surface = tok

        elseif Helpers.is_commercial(tok) then
            apply_commercial(spec, tok, commercial_state, label)

        else
            error("unrecognized label token: " .. tok)
        end
    end

    return spec
end

return Hydrate
