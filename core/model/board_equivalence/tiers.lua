local Tiers = {}

local function eq(a,b)
    return a and b and a == b
end

function Tiers.exact(a,b)

    return eq(a.h,b.h)
       and eq(a.w,b.w)
       and eq(a.l,b.l)
       and eq(a.tag,b.tag)
       and eq(a.grade,b.grade)

end


function Tiers.dim_grade(a,b)

    return eq(a.h,b.h)
       and eq(a.w,b.w)
       and eq(a.tag,b.tag)
       and eq(a.grade,b.grade)

end


function Tiers.family(a,b)

    return eq(a.h,b.h)
       and eq(a.w,b.w)
       and eq(a.tag,b.tag)

end

function Tiers.evaluate(a,b)

    if Tiers.exact(a,b) then
        return 1
    end

    if Tiers.dim_grade(a,b) then
        return 2
    end

    if Tiers.family(a,b) then
        return 3
    end

    return 4
end

return Tiers
