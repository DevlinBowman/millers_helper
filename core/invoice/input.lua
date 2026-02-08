-- core/invoice/input.lua
--
-- Adapts BoardCapture into Invoice input contract.
-- Mirrors compare.input behavior.

local Input = {}

--- @param capture table -- BoardCapture
--- @param source_id string|nil
--- @return table invoice_input
function Input.build(capture, source_id)
    assert(type(capture) == "table", "capture required")

    if source_id then
        for _, src in ipairs(capture.sources or {}) do
            if src.source_id == source_id then
                return {
                    boards = src.boards.data,
                }
            end
        end
        error("source not found: " .. tostring(source_id))
    end

    -- default: flatten ALL sources
    local boards = {}
    for _, src in ipairs(capture.sources or {}) do
        for _, b in ipairs(src.boards.data or {}) do
            if type(b.physical) == "table" then
                boards[#boards + 1] = b
            else
                local Board = require("core.board.board")
                boards[#boards + 1] = Board.new(b)
            end
        end
    end

    return { boards = boards }
end

return Input
