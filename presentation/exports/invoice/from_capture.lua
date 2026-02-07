-- presentation/exports/invoice/from_capture.lua
--
-- Adapts BoardCapture into Invoice input.

local M = {}

--- @param capture table -- BoardCapture
--- @param source_id string|nil -- choose a single source
--- @return table invoice_input
function M.build_input(capture, source_id)

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
        for _, b in ipairs(src.boards.data) do
            if b.physical then
                boards[#boards + 1] = b
            else
                -- flat board → project using Board.new recalc path
                local Board = require("core.board.board")
                boards[#boards + 1] = Board.new(b)
            end
        end
    end

    return { boards = boards }
end

return M
