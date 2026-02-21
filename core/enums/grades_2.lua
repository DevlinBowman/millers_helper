-- core/enums/grade.lua
--
-- System-level grade model.
-- Axis-based definition:
--   zone  ×  grain  →  grade
--
-- No printing.
-- No sorting side effects.
-- No presentation logic.

local Grade = {}

----------------------------------------------------------------
-- Zone Axis
----------------------------------------------------------------

Grade.ZONE = {

    COMMON = {
        kind = "value",
        domain = "grade.zone",
        key = "common",
        code = "C",
        rank = 1,
        multiplier = 1.00,
        description = "Common (sapwood) material.",
    },

    HEART = {
        kind = "value",
        domain = "grade.zone",
        key = "heart",
        code = "H",
        rank = 2,
        multiplier = 1.30,
        description = "Heartwood material.",
    },
}

----------------------------------------------------------------
-- Grain Axis
----------------------------------------------------------------

Grade.GRAIN = {

    MERCHANTABLE = {
        kind = "value",
        domain = "grade.grain",
        key = "merchantable",
        code = "M",
        rank = 1,
        multiplier = 0.75,
        description = "Merchantable structural grade.",
    },

    CONSTRUCTION = {
        kind = "value",
        domain = "grade.grain",
        key = "construction",
        code = "C",
        rank = 2,
        multiplier = 1.00,
        description = "Construction baseline grade.",
    },

    SELECT = {
        kind = "value",
        domain = "grade.grain",
        key = "select",
        code = "S",
        rank = 3,
        multiplier = 1.20,
        description = "Select grade material.",
    },

    B = {
        kind = "value",
        domain = "grade.grain",
        key = "b",
        code = "B",
        rank = 4,
        multiplier = 1.55,
        description = "B grade material.",
    },

    A = {
        kind = "value",
        domain = "grade.grain",
        key = "a",
        code = "A",
        rank = 5,
        multiplier = 2.70,
        description = "A / Clear grade material.",
    },
}

----------------------------------------------------------------
-- Derived Grade Combinations
----------------------------------------------------------------

Grade.COMBINATIONS = {}
Grade._index = {}

local BASE_VALUE = 1.0

local function build_combinations()
    for _, zone in pairs(Grade.ZONE) do
        for _, grain in pairs(Grade.GRAIN) do

            local tag = zone.code .. grain.code
            local label = grain.key .. "_" .. zone.key

            local value =
                BASE_VALUE
                * zone.multiplier
                * grain.multiplier

            local grade = {
                kind = "value",
                domain = "grade",
                tag = tag,
                label = label,

                zone = zone.key,
                grain = grain.key,

                zone_rank = zone.rank,
                grain_rank = grain.rank,
                rank = zone.rank + grain.rank,

                multiplier = value,
            }

            Grade.COMBINATIONS[#Grade.COMBINATIONS + 1] = grade

            Grade._index[string.lower(tag)] = grade
            Grade._index[string.lower(label)] = grade
        end
    end
end

build_combinations()

----------------------------------------------------------------
-- Lookup Sets
----------------------------------------------------------------

Grade.SET = {}
for _, g in ipairs(Grade.COMBINATIONS) do
    Grade.SET[g.tag] = true
end

----------------------------------------------------------------
-- Resolver
----------------------------------------------------------------

function Grade.get(key)
    if not key then return nil end

    if type(key) == "table" then
        return key
    end

    if type(key) == "string" then
        return Grade._index[string.lower(key)]
    end

    return nil
end

return Grade
