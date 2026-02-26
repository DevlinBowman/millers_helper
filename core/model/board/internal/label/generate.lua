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

    -- count (ALWAYS explicit)
    local count = spec.ct or 1
    assert(type(count) == "number" and count >= 1, "invalid count in spec")
    tokens[#tokens + 1] = "x" .. tostring(count)

    -- tag validation (defensive boundary check)
    local tag = spec.tag
    if tag ~= nil then
        if tag ~= "n" and tag ~= "c" and tag ~= "f" then
            error(
                string.format(
                    "Label.generate(): invalid tag '%s' for %sx%sx%s",
                    tostring(tag),
                    tostring(spec.base_h),
                    tostring(spec.base_w),
                    tostring(spec.l)
                ),
                2
            )
        end
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
