local Grade = require("core.model.board_equivalence.grade")

local Signal = {}

function Signal.build(a, b)

    if not a or not b then
        return "?"
    end

    local sig = {}

    if a.h and b.h and a.h == b.h then
        sig[#sig+1] = "H"
    end

    if a.w and b.w and a.w == b.w then
        sig[#sig+1] = "W"
    end

    if a.l and b.l and a.l == b.l then
        sig[#sig+1] = "L"
    end

    if a.tag and b.tag and a.tag == b.tag then
        sig[#sig+1] = "T"
    end

    if a.grade and b.grade and a.grade == b.grade then
        sig[#sig+1] = "G"
    end

    sig[#sig+1] = Grade.delta(a,b)

    return table.concat(sig)
end

return Signal
