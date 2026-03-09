local Grade  = require("core.model.board_equivalence.grade")
local Tiers  = require("core.model.board_equivalence.tiers")
local Signal = require("core.model.board_equivalence.signal")
local Debug  = require("core.model.board_equivalence.debug")

local BoardEquivalence = {}

function BoardEquivalence.match(order_board, candidates, opts)

    opts = opts or {}
    local debug_enabled = opts.debug == true

    if not order_board then
        return nil, "none"
    end

    local best
    local best_grade_distance
    local best_tier
    local best_dimension_distance

    for _, candidate in ipairs(candidates or {}) do

        ------------------------------------------------------------
        -- grade distance
        ------------------------------------------------------------

        local grade_distance =
            Grade.distance(order_board, candidate)

        if not grade_distance then
            grade_distance = math.huge
        end

        ------------------------------------------------------------
        -- tier evaluation
        ------------------------------------------------------------

        local tier =
            Tiers.evaluate(order_board, candidate)

        ------------------------------------------------------------
        -- dimension distance
        ------------------------------------------------------------

        local dimension_distance =
            math.abs((order_board.h or 0) - (candidate.h or 0)) +
            math.abs((order_board.w or 0) - (candidate.w or 0)) +
            math.abs((order_board.l or 0) - (candidate.l or 0))

        ------------------------------------------------------------
        -- debug
        ------------------------------------------------------------

        if debug_enabled then
            Debug.compare(
                order_board,
                candidate,
                grade_distance,
                tier,
                dimension_distance
            )
        end

        ------------------------------------------------------------
        -- selection cascade
        ------------------------------------------------------------

        if not best
        or grade_distance < best_grade_distance
        or (grade_distance == best_grade_distance and tier < best_tier)
        or (grade_distance == best_grade_distance
            and tier == best_tier
            and dimension_distance < best_dimension_distance)
        then

            best = candidate
            best_grade_distance = grade_distance
            best_tier = tier
            best_dimension_distance = dimension_distance

        end
    end

    if not best then
        return nil, "none"
    end

    if debug_enabled then
        Debug.select(order_board, best)
    end

    return best, Signal.build(order_board, best)
end

return BoardEquivalence
