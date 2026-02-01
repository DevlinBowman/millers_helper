-- ledger/analysis/summary.lua
--
-- Responsibility:
--   Read-only, high-level analysis of ledger contents.
--
-- Guarantees:
--   • No mutation
--   • No IO
--   • Deterministic
--   • Ledger-internal representation only
--
-- Produces structured summary data for:
--   • CLI
--   • UI
--   • Scripts
--   • Tests

local Summary = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function add(acc, v)
    if type(v) == "number" then
        return acc + v
    end
    return acc
end

local function min_date(a, b)
    if not a then return b end
    if not b then return a end
    return (a < b) and a or b
end

local function max_date(a, b)
    if not a then return b end
    if not b then return a end
    return (a > b) and a or b
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Produce a high-level summary of a ledger
---
--- @param ledger table
--- @return table summary
function Summary.run(ledger)
    assert(type(ledger) == "table", "ledger required")
    assert(type(ledger.facts) == "table", "ledger.facts required")

    local facts = ledger.facts

    local summary = {
        facts = {
            total = #facts,
        },

        boards = {
            total = 0,
            bf_total = 0,
            value_total = 0,
        },

        ingestions = {
            total = 0,
            by_source = {},
        },

        dates = {
            earliest = nil,
            latest   = nil,
        },
    }

    ----------------------------------------------------------------
    -- Facts / boards
    ----------------------------------------------------------------
    for _, fact in ipairs(facts) do
        local board = fact.board
        if type(board) == "table" then
            summary.boards.total = summary.boards.total + 1
            summary.boards.bf_total =
                add(summary.boards.bf_total, board.bf)
            summary.boards.value_total =
                add(summary.boards.value_total, board.value)

            if board.date then
                summary.dates.earliest =
                    min_date(summary.dates.earliest, board.date)
                summary.dates.latest =
                    max_date(summary.dates.latest, board.date)
            end
        end
    end

    ----------------------------------------------------------------
    -- Ingestions
    ----------------------------------------------------------------
    if type(ledger.ingestions) == "table" then
        summary.ingestions.total = #ledger.ingestions

        for _, ing in ipairs(ledger.ingestions) do
            local src = ing.source and ing.source.path
            if src then
                summary.ingestions.by_source[src] =
                    (summary.ingestions.by_source[src] or 0) + 1
            end
        end
    end

    return summary
end

return Summary
