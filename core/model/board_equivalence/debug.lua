local Debug = {}

------------------------------------------------------------
-- formatter
------------------------------------------------------------

local function fmt(b)

    if not b then
        return "nil"
    end

    return string.format(
        "%sx%sx%s %s %s",
        tostring(b.h or "?"),
        tostring(b.w or "?"),
        tostring(b.l or "?"),
        tostring(b.tag or "?"),
        tostring(b.grade or "?")
    )

end

------------------------------------------------------------
-- live matcher prints
------------------------------------------------------------

function Debug.compare(order, candidate, grade_delta, tier, dim_distance)

    print(
        "[COMPARE]",
        fmt(order),
        "vs",
        fmt(candidate),
        "| gradeΔ:", grade_delta,
        "| tier:", tier,
        "| dimΔ:", dim_distance
    )

end


function Debug.select(order, best)

    print(
        "[SELECT]",
        fmt(order),
        "→",
        fmt(best)
    )

end


------------------------------------------------------------
-- trace printer
------------------------------------------------------------

function Debug.print_trace(trace)

    if not trace then
        return
    end

    for _, c in ipairs(trace.comparisons or {}) do

        print(
            "[COMPARE]",
            fmt(c.order),
            "vs",
            fmt(c.candidate),
            "| gradeΔ:", c.grade_delta,
            "| tier:", c.tier,
            "| dimΔ:", c.dim_distance
        )

    end

    if trace.final then

        print(
            "[SELECT]",
            fmt(trace.final.order),
            "→",
            fmt(trace.final.candidate)
        )

    end

end

return Debug
