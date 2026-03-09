local Schema = require("core.schema").schema

local Grade = {}

------------------------------------------------------------
-- grade cache
------------------------------------------------------------

local function build_grade_cache()

    local map = {}
    local values = Schema.values("board.grade") or {}

    for _, rec in ipairs(values) do
        map[rec.name] = rec.rank or 0
    end

    return map
end

local VALUE = build_grade_cache()

-- keep compatibility with existing code
Grade.VALUE = VALUE

------------------------------------------------------------
-- access helpers
------------------------------------------------------------

function Grade.rank(grade)

    if not grade then
        return nil
    end

    return VALUE[grade]
end

function Grade.distance(a, b)

    local ga = a and a.grade
    local gb = b and b.grade

    if not ga or not gb then
        return nil
    end

    local va = VALUE[ga]
    local vb = VALUE[gb]

    if not va or not vb then
        return nil
    end

    return math.abs(vb - va)
end

------------------------------------------------------------
-- signal delta
------------------------------------------------------------

function Grade.delta(a, b)

    local d = Grade.distance(a, b)

    if not d then
        return "?"
    end

    if d <= 0.01 then
        return "="
    end

    if Grade.rank(b.grade) > Grade.rank(a.grade) then
        return "+"
    end

    return "-"
end

return Grade
