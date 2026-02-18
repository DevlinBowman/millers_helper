-- core/enums/grades.lua
-- Axis-first grading model with market-faithful grade multipliers (Redwood)

local Grade = {}

----------------------------------------------------------------
-- AXES (authoritative meaning)
----------------------------------------------------------------
-- Ranks: categorical ordering only
-- Multipliers: grade-only desirability pressure (dimensionless)

Grade.ZONE = {
    common = { rank = 1, name = "Common", code = "C", multiplier = 1.00 },
    heart  = { rank = 2, name = "Heart",  code = "H", multiplier = 1.30 },
}

Grade.GRAIN = {
    merchantable = { rank = 1, name = "Merchantable", code = "M", multiplier = 0.75 },
    construction = { rank = 2, name = "Construction", code = "C", multiplier = 1.00 }, -- baseline
    select       = { rank = 3, name = "Select",       code = "S", multiplier = 1.20 },
    b            = { rank = 4, name = "B",            code = "B", multiplier = 1.55 },
    a            = { rank = 5, name = "A / Clear",    code = "A", multiplier = 2.70 },
}

----------------------------------------------------------------
-- STORAGE
----------------------------------------------------------------

Grade.grades  = {}   -- ordered list of grade objects
Grade._index  = {}   -- tag + label → grade
Grade.symbols = {}   -- zone + grain → symbol objects

----------------------------------------------------------------
-- SYMBOL CONSTRUCTION (zones + grains)
----------------------------------------------------------------

for key, z in pairs(Grade.ZONE) do
    Grade.symbols[key] = {
        kind       = "zone",
        key        = key,
        name       = z.name,
        code       = z.code,
        rank       = z.rank,
        multiplier = z.multiplier,
    }
end

for key, g in pairs(Grade.GRAIN) do
    Grade.symbols[key] = {
        kind       = "grain",
        key        = key,
        name       = g.name,
        code       = g.code,
        rank       = g.rank,
        multiplier = g.multiplier,
    }
end

----------------------------------------------------------------
-- GRADE DERIVATION
----------------------------------------------------------------

local BASE_VALUE = 1.0 -- CC anchor

local function grade_code(zone, grain)
    return zone.code .. grain.code
end

for zone_key, zone in pairs(Grade.ZONE) do
    for grain_key, grain in pairs(Grade.GRAIN) do
        local tag   = grade_code(zone, grain)
        local label = string.format("%s %s", grain.name, zone.name)

        local value =
            BASE_VALUE
            * grain.multiplier
            * zone.multiplier

        local grade = {
            kind  = "grade",

            -- identity
            tag   = tag,
            label = label,

            -- structure
            zone  = zone_key,
            grain = grain_key,

            -- ordering
            zone_rank  = zone.rank,
            grain_rank = grain.rank,
            rank       = zone.rank + grain.rank,

            -- grade-only baseline multiplier
            value = value,
        }

        Grade.grades[#Grade.grades + 1] = grade
        Grade._index[tag]   = grade
        Grade._index[label] = grade
    end
end

----------------------------------------------------------------
-- RESOLVER
----------------------------------------------------------------
-- Resolves grades, zones, grains, or already-resolved objects

function Grade.get(key)
    if key == nil then return nil end

    if type(key) == "table" then
        return key
    end

    if type(key) == "string" then
        return Grade._index[key] or Grade.symbols[key]
    end

    return nil
end

----------------------------------------------------------------
-- COMPARATORS
----------------------------------------------------------------

function Grade.higher_rank(a, b)
    a, b = Grade.get(a), Grade.get(b)
    if not a or not b then return false end
    return (a.rank or 0) > (b.rank or 0)
end

function Grade.higher_value(a, b)
    a, b = Grade.get(a), Grade.get(b)
    if not a or not b then return false end
    return (a.value or 0) > (b.value or 0)
end

----------------------------------------------------------------
-- PRINTING
----------------------------------------------------------------

-- Print a single grade / zone / grain on one line
function Grade.print(item)
    local g = Grade.get(item)

    if not g then
        print("nil")
        return
    end

    if g.kind == "grade" then
        print(string.format(
            "%-3s | %-22s | Z:%-6s(%d) G:%-13s(%d) | R:%-2d V:%6.2f",
            g.tag,
            g.label,
            g.zone,
            g.zone_rank,
            g.grain,
            g.grain_rank,
            g.rank,
            g.value
        ))
        return
    end

    -- zone / grain symbol
    print(string.format(
        "%-5s | %-14s | kind:%-6s | R:%-2d M:%5.2f",
        g.key,
        g.name,
        g.kind,
        g.rank,
        g.multiplier
    ))
end

-- Print all grades, sorted by value
function Grade.print_all()
    table.sort(Grade.grades, function(a, b)
        if a.value ~= b.value then
            return a.value < b.value
        end
        return a.rank < b.rank
    end)

    for _, g in ipairs(Grade.grades) do
        Grade.print(g)
    end
end

local function print_all_grades()
    print("==================================================")
    print("LUMBER GRADE ENUM DUMP (SORTED BY VALUE)")
    print("==================================================")

    table.sort(Grade.grades, function(a, b)
        if a.value ~= b.value then
            return a.value < b.value
        end
        return a.rank < b.rank
    end)

    print("TAG | LABEL                  | ZONE         GRAIN             | R  VALUE")
    print("--------------------------------------------------------------------------")

    for _, g in ipairs(Grade.grades) do
        print(string.format(
            "%-3s | %-22s | Z:%-6s(%d) G:%-13s(%d) | R:%-2d V:%6.2f",
            g.tag,
            g.label,
            g.zone,
            g.zone_rank,
            g.grain,
            g.grain_rank,
            g.rank,
            g.value
        ))
    end

    print("==================================================")
    print(string.format("Total combinations: %d", #Grade.grades))
    print("==================================================")
end

----------------------------------------------------------------
-- EXAMPLES (usage patterns)
----------------------------------------------------------------
-- These are illustrative only. Remove or comment out in production.

---- Resolve grades by tag or label
-- local g1 = Grade.get("HA")
-- local g2 = Grade.get("Construction Common")

---- Access grade properties
-- print(g1.label)          -- "A / Clear Heart"
-- print(g1.value)          -- grade-only multiplier
-- print(g1.rank)           -- structural ordering

---- Resolve axis symbols directly
-- local zone = Grade.get("heart")
-- local grain = Grade.get("select")

---- Axis-level introspection
-- print(zone.multiplier)   -- durability pressure
-- print(grain.rank)        -- grain ordering

---- Comparisons
-- print(Grade.higher_value("HA", "CS"))   -- true
-- print(Grade.higher_rank("HB", "CA"))    -- depends on rank model

---- One-line inspection
-- Grade.print("HB")
-- Grade.print("select")
-- Grade.print("heart")

---- Full table dump (sorted by value)
-- print_all_grades()

----------------------------------------------------------------
-- MODULE EXPORT
----------------------------------------------------------------

return Grade
