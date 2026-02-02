-- presentation/exports/compare/from_capture.lua
--
-- Adapts BoardCapture into Compare input contract.
-- NO mutation. NO math. NO matching.

local M = {}

--- @param capture table -- BoardCapture
--- @param order   table -- { id, boards }
--- @param opts    table|nil
--- @return table compare_input
function M.build_input(capture, order, opts)
    opts = opts or {}

    assert(type(capture) == "table", "capture required")
    assert(type(order) == "table", "order required")
    assert(type(order.boards) == "table", "order.boards required")

    local sources = {}

    for _, src in ipairs(capture.sources or {}) do
        sources[#sources + 1] = {
            name   = opts.name_map and opts.name_map[src.source_id]
                     or src.source_id,
            boards = src.boards.data,
        }
    end

    return {
        order = {
            id     = order.id,
            boards = order.boards,
        },
        sources = sources,
    }
end

return M
