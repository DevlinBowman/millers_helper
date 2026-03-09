local Trace = {}

function Trace.new()

    return {
        comparisons = {},
        selections  = {},
        final       = nil
    }

end

function Trace.record_compare(trace, order, candidate, grade_delta, tier, dim_distance)

    trace.comparisons[#trace.comparisons + 1] = {
        order  = order,
        candidate = candidate,
        grade_delta = grade_delta,
        tier = tier,
        dim_distance = dim_distance
    }

end

function Trace.record_select(trace, order, candidate)

    trace.selections[#trace.selections + 1] = {
        order = order,
        candidate = candidate
    }

end

function Trace.record_final(trace, order, candidate)

    trace.final = {
        order = order,
        candidate = candidate
    }

end

return Trace
