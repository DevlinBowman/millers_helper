-- core/board/label/generate.lua
--
-- Label generation (authoritative encoding).

local Helpers = require("core.model.board.internal.label.helpers")

local Generate = {}

--- Generate a label string from a specification table.
---
--- @param spec table
--- @return string
function Generate.from_spec(spec)
    assert(type(spec) == "table", "spec required")
    assert(spec.base_h and spec.base_w and spec.l, "missing declared dimensions")

    local tokens = {}

    -- dimensions (always first)
    tokens[#tokens + 1] = Helpers.format_dimension(spec)

    -- count
    if spec.ct and spec.ct > 1 then
        tokens[#tokens + 1] = "x" .. tostring(spec.ct)
    end

    -- commercial codes (ordered)
    if spec.species  then tokens[#tokens + 1] = spec.species end
    if spec.grade    then tokens[#tokens + 1] = spec.grade end
    if spec.moisture then tokens[#tokens + 1] = spec.moisture end

    -- surface
    if spec.surface then
        tokens[#tokens + 1] = spec.surface
    end

    return table.concat(tokens, " ")
end

return Generate
